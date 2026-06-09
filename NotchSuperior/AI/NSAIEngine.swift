// NOTCHSUPERIOR ADDITION
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

        // Add user message
        let userMsg = NSAIChatMessage(id: UUID(), role: "user",
                                      content: text, timestamp: Date())
        conversations[idx].messages.append(userMsg)
        conversations[idx].updatedAt = Date()

        // Auto-title on first message
        if conversations[idx].messages.count == 1 {
            conversations[idx].title = String(text.prefix(40))
        }

        // Build assistant placeholder
        let assistantMsg = NSAIChatMessage(id: UUID(), role: "assistant",
                                           content: "", timestamp: Date())
        conversations[idx].messages.append(assistantMsg)
        let assistantIdx = conversations[idx].messages.count - 1

        isStreaming = true
        streamingText = ""
        errorMessage = nil

        let messages = conversations[idx].messages.dropLast()  // exclude empty assistant
        let systemPrompt: String = contextText.map {
            "The user has the following context selected:\n\n\($0)\n\nAnswer with this in mind."
        } ?? "You are a helpful assistant built into the macOS menu bar notch. Be concise."

        streamTask = Task {
            do {
                let stream = try await streamCompletion(
                    messages: Array(messages),
                    systemPrompt: systemPrompt,
                    apiKey: apiKey,
                    provider: selectedProvider)
                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    streamingText += chunk
                    conversations[idx].messages[assistantIdx].content = streamingText
                }
            } catch {
                conversations[idx].messages[assistantIdx].content =
                    "Error: \(error.localizedDescription)"
                errorMessage = error.localizedDescription
            }
            isStreaming = false
            save()
        }
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

    // Returns an AsyncThrowingStream<String, Error> of text chunks.
    // Implements SSE parsing for OpenAI/Claude and JSON for Gemini.

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
        req.timeoutInterval = 60

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

        case .claude:
            req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = [
                "model": "claude-opus-4-5",
                "max_tokens": 2048,
                "stream": true,
                "system": systemPrompt,
                "messages": messages.map { ["role":$0.role, "content":$0.content] }
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)

        case .gemini:
            // Gemini doesn't support SSE stream the same way;
            // use non-streaming endpoint for Gemini and collect full response.
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

    // Parses a single SSE line and returns the text delta, or nil.
    private func parseSSELine(_ line: String,
                              provider: NSAIProvider) -> String? {
        guard line.hasPrefix("data: ") else {
            // Gemini returns full JSON, not SSE
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
        case .openAI:
            return (json["choices"] as? [[String:Any]])?.first
                .flatMap { $0["delta"] as? [String:Any] }
                .flatMap { $0["content"] as? String }
        case .claude:
            if let type_ = json["type"] as? String, type_ == "content_block_delta",
               let delta = json["delta"] as? [String:Any],
               let text = delta["text"] as? String { return text }
            return nil
        case .gemini:
            return nil  // handled above
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
