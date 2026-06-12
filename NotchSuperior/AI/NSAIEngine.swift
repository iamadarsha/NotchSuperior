// ────────────────────────────────────────────────────────
// NotchSuperior — NSAIEngine.swift
// FIX 3: SSE retry/reconnect on stream drop, configurable timeout,
//         partial-response display on error instead of silent hang.
// FIX 4: New dedicated summarize(text:systemPrompt:) bypasses
//         conversation validation — NSAINoteEngine no longer needs
//         to inject a fake conversation.
// ────────────────────────────────────────────────────────

import Foundation
import SwiftUI

@MainActor
class NSAIEngine: ObservableObject {
    static let shared = NSAIEngine()

    @Published var conversations: [NSAIConversation] = []
    @Published var isStreaming: Bool = false
    @Published var streamingText: String = ""
    @Published var errorMessage: String? = nil

    private var streamTask: Task<Void, Never>?

    // MARK: — SSE retry config (FIX 3)
    private let maxRetries = 2
    private let retryDelayNS: UInt64 = 1_500_000_000   // 1.5 s

    // MARK: — Provider selection
    @AppStorage("NSAISelectedProvider") var selectedProviderRaw: String = NSAIProvider.openAI.rawValue
    var selectedProvider: NSAIProvider {
        NSAIProvider(rawValue: selectedProviderRaw) ?? .openAI
    }

    var isConfigured: Bool { NSAIKeyStore.shared.hasKey(for: selectedProvider) }

    // MARK: — Chat

    func newConversation() -> NSAIConversation {
        let conv = NSAIConversation(
            id: UUID(), title: "New Chat",
            provider: selectedProvider, messages: [],
            createdAt: Date(), updatedAt: Date())
        conversations.insert(conv, at: 0)
        save()
        return conv
    }

    func sendMessage(_ text: String, in convID: UUID,
                     contextText: String? = nil) async {
        guard let idx = conversations.firstIndex(where: { $0.id == convID })
        else { return }
        guard let apiKey = NSAIKeyStore.shared.load(for: selectedProvider) else {
            errorMessage = "No API key set for \(selectedProvider.displayName). Add it in Settings → AI."
            return
        }

        let userMsg = NSAIChatMessage(id: UUID(), role: "user",
                                      content: text, timestamp: Date())
        conversations[idx].messages.append(userMsg)
        conversations[idx].updatedAt = Date()
        if conversations[idx].messages.count == 1 {
            conversations[idx].title = String(text.prefix(40))
        }

        let assistantMsg = NSAIChatMessage(id: UUID(), role: "assistant",
                                           content: "", timestamp: Date())
        conversations[idx].messages.append(assistantMsg)
        let assistantIdx = conversations[idx].messages.count - 1

        isStreaming = true
        streamingText = ""
        errorMessage = nil

        let messages = Array(conversations[idx].messages.dropLast())
        let systemPrompt: String = contextText.map {
            "The user has the following context selected:\n\n\($0)\n\nAnswer with this in mind."
        } ?? "You are a helpful assistant built into the macOS menu bar notch. Be concise."

        streamTask = Task {
            // FIX 3: retry loop — up to maxRetries reconnects on stream drop
            var attempt = 0
            var accumulated = ""
            repeat {
                do {
                    let stream = try await streamCompletion(
                        messages: messages,
                        systemPrompt: systemPrompt,
                        apiKey: apiKey,
                        provider: selectedProvider)
                    for try await chunk in stream {
                        guard !Task.isCancelled else { break }
                        accumulated += chunk
                        streamingText = accumulated
                        conversations[idx].messages[assistantIdx].content = accumulated
                    }
                    break  // clean finish — exit retry loop
                } catch {
                    attempt += 1
                    if attempt > maxRetries || Task.isCancelled {
                        // FIX 3: Show partial response + error notice instead of hanging
                        let partial = accumulated.isEmpty ? "" : accumulated + "\n\n"
                        conversations[idx].messages[assistantIdx].content =
                            partial + "⚠ Connection lost: \(error.localizedDescription)"
                        errorMessage = error.localizedDescription
                        break
                    }
                    // Wait before retrying
                    try? await Task.sleep(nanoseconds: retryDelayNS)
                }
            } while !Task.isCancelled

            isStreaming = false
            save()
        }
    }

    // FIX 4: Dedicated summarize method — bypasses conversation validation.
    // NSAINoteEngine calls this directly; no fake conversation injection needed.
    func summarize(text: String, systemPrompt: String) async -> String {
        guard let apiKey = NSAIKeyStore.shared.load(for: selectedProvider) else {
            return "⚠ No API key set for \(selectedProvider.displayName). Add it in Settings → AI."
        }
        let userMsg = NSAIChatMessage(id: UUID(), role: "user",
                                      content: text, timestamp: Date())
        var result = ""
        var attempt = 0
        repeat {
            do {
                let stream = try await streamCompletion(
                    messages: [userMsg],
                    systemPrompt: systemPrompt,
                    apiKey: apiKey,
                    provider: selectedProvider)
                for try await chunk in stream {
                    result += chunk
                }
                break
            } catch {
                attempt += 1
                if attempt > maxRetries { break }
                try? await Task.sleep(nanoseconds: retryDelayNS)
            }
        } while true
        return result.isEmpty ? "⚠ Summarization failed. Try again." : result
    }

    func cancelStream() {
        streamTask?.cancel()
        isStreaming = false
    }

    func deleteConversation(_ id: UUID) {
        conversations.removeAll { $0.id == id }
        save()
    }

    // MARK: — Streaming network layer

    private func streamCompletion(
        messages: [NSAIChatMessage],
        systemPrompt: String,
        apiKey: String,
        provider: NSAIProvider
    ) async throws -> AsyncThrowingStream<String, Error> {

        let request = try buildRequest(messages: messages,
                                       systemPrompt: systemPrompt,
                                       apiKey: apiKey,
                                       provider: provider)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared
                        .bytes(for: request)
                    guard let httpResp = response as? HTTPURLResponse,
                          (200...299).contains(httpResp.statusCode) else {
                        throw URLError(.badServerResponse)
                    }
                    for try await line in bytes.lines {
                        guard !Task.isCancelled else { break }
                        if let chunk = parseSSELine(line, provider: provider) {
                            continuation.yield(chunk)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func buildRequest(messages: [NSAIChatMessage],
                               systemPrompt: String,
                               apiKey: String,
                               provider: NSAIProvider) throws -> URLRequest {
        var req = URLRequest(url: URL(string: provider.baseURL)!)
        req.httpMethod = "POST"
        // FIX 3: explicit timeout so URLSession doesn't hang indefinitely
        req.timeoutInterval = 45

        switch provider {
        case .openAI:
            req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = [
                "model": "gpt-4o",
                "stream": true,
                "messages": [["role":"system","content":systemPrompt]]
                    + messages.map { ["role":$0.role, "content":$0.content] }
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)

        case .groq:
            req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let systemMsg = NSAIChatMessage(id: UUID(), role: "system", content: systemPrompt, timestamp: Date())
            let apiMessages = ([systemMsg] + messages).map { msg -> [String: String] in
                ["role": msg.role, "content": msg.content]
            }
            let payload: [String: Any] = [
                "model": "llama-3.3-70b-versatile",
                "messages": apiMessages,
                "stream": true
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        case .gemini:
            var components = URLComponents(string: provider.baseURL)!
            components.queryItems = [URLQueryItem(name:"key", value:apiKey)]
            req.url = components.url
            let contents = messages.map { msg -> [String:Any] in
                let role = msg.role == "assistant" ? "model" : "user"
                return ["role": role, "parts": [["text": msg.content]]]
            }
            let body: [String: Any] = [
                "system_instruction": ["parts": [["text": systemPrompt]]],
                "contents": contents,
                "generationConfig": ["maxOutputTokens": 2048]
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return req
    }

    private func parseSSELine(_ line: String,
                              provider: NSAIProvider) -> String? {
        guard line.hasPrefix("data: ") else {
            if provider == .gemini, !line.isEmpty,
               let data = line.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
               let candidates = json["candidates"] as? [[String:Any]],
               let content = candidates.first?["content"] as? [String:Any],
               let parts = content["parts"] as? [[String:Any]],
               let text = parts.first?["text"] as? String {
                return text
            }
            return nil
        }
        let payload = String(line.dropFirst(6))
        guard payload != "[DONE]",
              let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any]
        else { return nil }

        switch provider {
        case .openAI, .groq:
            return (json["choices"] as? [[String:Any]])?.first
                .flatMap { $0["delta"] as? [String:Any] }
                .flatMap { $0["content"] as? String }
        case .gemini:
            return nil
        }
    }

    // MARK: — Persistence
    private var storeURL: URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NotchSuperior", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir,
            withIntermediateDirectories: true)
        return dir.appendingPathComponent("ai_conversations.json")
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(conversations) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let list = try? JSONDecoder().decode(
                  [NSAIConversation].self, from: data)
        else { return }
        conversations = list
    }
}
