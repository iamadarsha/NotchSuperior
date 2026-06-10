// ────────────────────────────────────────────────────────
// NotchSuperior — NSAINoteEngine.swift
// FIX 4: Removed fake-conversation injection pattern.
//         Now calls NSAIEngine.summarize(text:systemPrompt:)
//         directly — a clean, validated code path that does
//         not pollute the conversations list.
// ────────────────────────────────────────────────────────

import Foundation
import AVFoundation
import Speech
import Cocoa

@MainActor
class NSAINoteEngine: ObservableObject {
    static let shared = NSAINoteEngine()

    @Published var notes: [NSAINote] = []
    @Published var isProcessing = false

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    @Published var isRecording = false
    @Published var liveTranscript = ""

    // MARK: — Voice recording
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

        recognitionTask = recognizer?.recognitionTask(with: req) { [weak self] result, _ in
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

    // MARK: — AI summarization (FIX 4)
    // Uses NSAIEngine.summarize(text:systemPrompt:) — a dedicated path
    // that streams a one-shot completion without touching the conversations list.
    func summarize(text: String, template: NSAINoteTemplate,
                   noteID: UUID) async {
        guard let idx = notes.firstIndex(where: { $0.id == noteID }) else { return }
        guard NSAIEngine.shared.isConfigured else {
            notes[idx].summary = "⚠ No AI key set. Add one in Settings → AI."
            return
        }
        isProcessing = true
        notes[idx].summary = nil   // clear stale summary while processing

        let summary = await NSAIEngine.shared.summarize(
            text: text,
            systemPrompt: template.systemPrompt)

        notes[idx].summary = summary
        notes[idx].updatedAt = Date()
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
