// NOTCHSUPERIOR ADDITION
import Foundation
import AVFoundation
import Speech
import Cocoa

@MainActor
class NSAINoteEngine: ObservableObject {
    static let shared = NSAINoteEngine()

    @Published var notes: [NSAINote] = []
    @Published var isProcessing = false

    // MARK: — Voice transcription (using SFSpeechRecognizer)
    // Uses Apple's on-device speech framework — no network call for transcription.
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    @Published var isRecording = false
    @Published var liveTranscript = ""

    func startRecording() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else { return }
            Task { @MainActor in self?.beginAudioCapture() }
        }
    }

    private func beginAudioCapture() {
        let recognizer = SFSpeechRecognizer(locale: Locale.current)
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let req = recognitionRequest else { return }
        req.shouldReportPartialResults = true

        recognitionTask = recognizer?.recognitionTask(with: req) { [weak self] result, error in
            if let result { self?.liveTranscript = result.bestTranscription.formattedString }
        }

        let inputNode = audioEngine.inputNode
        let fmt = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: fmt) { buf, _ in
            req.append(buf)
        }
        audioEngine.prepare()
        try? audioEngine.start()
        isRecording = true
    }

    func stopRecording() -> String {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isRecording = false
        let result = liveTranscript
        liveTranscript = ""
        return result
    }

    // MARK: — AI summarization
    func summarize(text: String, template: NSAINoteTemplate,
                   noteID: UUID) async {
        guard let idx = notes.firstIndex(where: { $0.id == noteID }) else { return }
        guard NSAIEngine.shared.isConfigured else {
            notes[idx].summary = "⚠ No AI key set. Add one in Settings → AI."
            return
        }
        isProcessing = true

        // Create a temporary conversation just for summarization
        let convID = UUID()
        var tmpConv = NSAIConversation(id: convID,
            title: "Note Summarization", provider: NSAIEngine.shared.selectedProvider,
            messages: [], createdAt: Date(), updatedAt: Date())
        let userMsg = NSAIChatMessage(id: UUID(), role: "user",
            content: text, timestamp: Date())
        tmpConv.messages = [userMsg]

        // Add temporary conversation to engine list to be used by sendMessage
        NSAIEngine.shared.conversations.insert(tmpConv, at: 0)

        await NSAIEngine.shared.sendMessage(
            text,
            in: convID,
            contextText: template.systemPrompt)

        // Extract last assistant message
        if let conv = NSAIEngine.shared.conversations.first(where:{ $0.id == convID }),
           let last = conv.messages.last(where:{ $0.role == "assistant" }) {
            notes[idx].summary = last.content
            notes[idx].updatedAt = Date()
        }

        // Clean up temporary conversation
        NSAIEngine.shared.deleteConversation(convID)
        isProcessing = false
        save()
    }

    // MARK: — CRUD
    func createNote(title: String = "New Note",
                    template: NSAINoteTemplate = .freeform) -> NSAINote {
        let note = NSAINote(id: UUID(), title: title, template: template,
                            createdAt: Date(), updatedAt: Date())
        notes.insert(note, at: 0)
        save()
        return note
    }

    func updateNote(_ note: NSAINote) {
        if let i = notes.firstIndex(where: { $0.id == note.id }) {
            notes[i] = note
            notes[i].updatedAt = Date()
            save()
        }
    }

    func deleteNote(_ id: UUID) {
        notes.removeAll { $0.id == id }
        save()
    }

    func exportNote(_ note: NSAINote) {
        let text = [note.title,
                    note.rawTranscript.map { "--- Transcript ---\n\($0)" } ?? "",
                    note.summary.map { "--- Summary ---\n\($0)" } ?? ""]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    // MARK: — Persistence
    private var storeURL: URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NotchSuperior", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir,
            withIntermediateDirectories: true)
        return dir.appendingPathComponent("ai_notes.json")
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let list = try? JSONDecoder().decode([NSAINote].self, from: data)
        else { return }
        notes = list
    }
}
