import Foundation
import SwiftUI
import AVFoundation

enum TranscriptionProvider: String, CaseIterable, Identifiable {
    case groq = "groq"
    case openai = "openai"
    case gemini = "gemini"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .groq: return "Groq"
        case .openai: return "OpenAI Whisper"
        case .gemini: return "Google Gemini"
        }
    }
    
    var endpoint: String {
        switch self {
        case .groq:
            return "https://api.groq.com/openai/v1/audio/transcriptions"
        case .openai:
            return "https://api.openai.com/v1/audio/transcriptions"
        case .gemini:
            return "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
        }
    }
    
    var model: String {
        switch self {
        case .groq: return "whisper-large-v3-turbo"
        case .openai: return "whisper-1"
        case .gemini: return "gemini-2.5-flash"
        }
    }
}

enum TranscriptionError: LocalizedError {
    case missingAPIKey(String)
    case submissionFailed(String)
    case transcriptionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let msg): return msg
        case .submissionFailed(let msg): return "Transcription request failed: \(msg)"
        case .transcriptionFailed(let msg): return "Transcription failed: \(msg)"
        }
    }
}

class VoiceNotesManager: ObservableObject {
    static let shared = VoiceNotesManager()
    
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var lastTranscript: String = ""
    
    @AppStorage("voiceNotesProvider") var selectedProvider: TranscriptionProvider = .groq
    
    private let recorder = AudioRecorder()
    
    private init() {
    }
    
    func startRecording() {
        lastTranscript = ""
        try? recorder.startRecording()
    }
    
    func stopRecordingAndTranscribe() async throws -> String {
        guard recorder.isRecording else { throw TranscriptionError.transcriptionFailed("Not recording") }
        
        guard let url = recorder.stopRecording() else {
            throw TranscriptionError.transcriptionFailed("No recording found.")
        }
        
        return try await transcribe(fileURL: url)
    }
    
    private func transcribe(fileURL: URL) async throws -> String {
        await MainActor.run { self.isTranscribing = true }
        defer { Task { @MainActor in self.isTranscribing = false } }
        
        let result: String
        switch selectedProvider {
        case .groq, .openai:
            result = try await transcribeOpenAICompatible(fileURL: fileURL, provider: selectedProvider)
        case .gemini:
            result = try await transcribeGemini(fileURL: fileURL)
        }
        
        await MainActor.run { self.lastTranscript = result }
        return result
    }
    
    private func transcribeOpenAICompatible(fileURL: URL, provider: TranscriptionProvider) async throws -> String {
        let nsProvider: NSAIProvider = provider == .groq ? .groq : .openAI
        guard let apiKey = NSAIKeyStore.shared.load(for: nsProvider) else {
            throw TranscriptionError.missingAPIKey("\(provider.displayName) API key is missing. Please set it in Settings.")
        }
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw TranscriptionError.missingAPIKey("\(provider.displayName) API key is missing. Please set it in Settings.")
        }
        
        guard let endpointURL = URL(string: provider.endpoint) else {
            throw TranscriptionError.submissionFailed("Invalid endpoint URL")
        }
        
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let audioData = try Data(contentsOf: fileURL)
        var body = Data()
        let fileName = fileURL.lastPathComponent
        
        func append(_ value: String) { body.append(Data(value.utf8)) }
        
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        append("\(provider.model)\r\n")
        
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        append("Content-Type: audio/wav\r\n\r\n")
        body.append(audioData)
        append("\r\n")
        append("--\(boundary)--\r\n")
        
        let (data, response) = try await URLSession.shared.upload(for: request, from: body)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.submissionFailed("No response from server")
        }
        
        if httpResponse.statusCode != 200 {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TranscriptionError.submissionFailed(errorString)
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let text = json["text"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        throw TranscriptionError.transcriptionFailed("Invalid response format")
    }
    
    private func transcribeGemini(fileURL: URL) async throws -> String {
        guard let apiKey = NSAIKeyStore.shared.load(for: .gemini) else {
            throw TranscriptionError.missingAPIKey("Gemini API key is missing. Please set it in Settings.")
        }
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw TranscriptionError.missingAPIKey("Gemini API key is missing. Please set it in Settings.")
        }
        
        guard var components = URLComponents(string: TranscriptionProvider.gemini.endpoint) else {
            throw TranscriptionError.submissionFailed("Invalid Gemini endpoint URL")
        }
        components.queryItems = [URLQueryItem(name: "key", value: trimmedKey)]
        
        guard let endpointURL = components.url else {
            throw TranscriptionError.submissionFailed("Invalid Gemini endpoint URL")
        }
        
        let audioData = try Data(contentsOf: fileURL)
        let payload: [String: Any] = [
            "contents": [["parts": [
                ["text": "Transcribe this audio exactly. Return only the transcript text."],
                ["inlineData": ["mimeType": "audio/wav", "data": audioData.base64EncodedString()]]
            ]]],
            "generationConfig": ["temperature": 0.0]
        ]
        
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.submissionFailed("No response from Gemini")
        }
        
        if httpResponse.statusCode != 200 {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TranscriptionError.submissionFailed(errorString)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw TranscriptionError.transcriptionFailed("Invalid Gemini transcription response")
        }
        
        let combined = parts.compactMap { $0["text"] as? String }.joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !combined.isEmpty else {
            throw TranscriptionError.transcriptionFailed("Gemini returned empty transcript")
        }
        
        return combined
    }
}
