// ────────────────────────────────────────────────────────
// NotchSuperior — NSAINoteEngine.swift
//
// FIX (Issue 3 – Voice Notes Not Saving):
//   Replaced AVAudioEngine + SFSpeechRecognizer streaming
//   (race condition: recognitionTask?.cancel() killed the
//   final result before liveTranscript was populated)
//   with AVAudioRecorder → WAV file →
//   SFSpeechURLRecognitionRequest (file-based, non-streaming).
//
//   Guarantees:
//   1. Full audio on disk before recognition starts — no race.
//   2. isFinal result always delivered — no cancel() problem.
//   3. No AVAudioEngine tap-reuse crash on second recording.
//   4. Transcript delivered async via @Published notes array.
//      stopRecording() is now void (callers must not assign return).
//
// FIX 4 (previous): summarize() uses NSAIEngine.summarize() — unchanged.
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
    @Published var isRecording = false
    @Published var liveTranscript = ""

    // MARK: — Private recording state
    private var audioRecorder: AVAudioRecorder?
    private var currentRecordingURL: URL?
    private var pendingNoteID: UUID?

    // MARK: — startRecording(for:)
    func startRecording(for noteID: UUID) {
        pendingNoteID = noteID
        liveTranscript = ""

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            beginFileRecording()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                Task { @MainActor [weak self] in
                    if granted {
                        self?.beginFileRecording()
                    } else {
                        self?.setTranscript(
                            "⚠ Microphone access denied. Enable it in System Settings → Privacy & Security → Microphone.",
                            for: noteID)
                    }
                }
            }
        default:
            setTranscript(
                "⚠ Microphone access denied. Enable it in System Settings → Privacy & Security → Microphone.",
                for: noteID)
        }
    }

    private func beginFileRecording() {
        // Write to /tmp — always sandbox-writable, no extra entitlements needed.
        let tmp = FileManager.default.temporaryDirectory
        let url = tmp
            .appendingPathComponent("ns_voicenote_\(UUID().uuidString)")
            .appendingPathExtension("wav")
        currentRecordingURL = url

        // 16-bit PCM 16 kHz mono — optimal for SFSpeechRecognizer.
        let settings: [String: Any] = [
            AVFormatIDKey:             Int(kAudioFormatLinearPCM),
            AVSampleRateKey:           16_000.0,
            AVNumberOfChannelsKey:     1,
            AVLinearPCMBitDepthKey:    16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey:     false
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            isRecording = true
        } catch {
            NSLog("[NSAINoteEngine] AVAudioRecorder init failed: \(error)")
            audioRecorder = nil
            currentRecordingURL = nil
        }
    }

    // MARK: — stopRecording()
    // Now VOID — transcript is delivered async via the notes @Published array.
    // Callers must NOT assign a return value.
    func stopRecording() {
        guard let recorder = audioRecorder, let url = currentRecordingURL else {
            isRecording = false
            return
        }
        recorder.stop()
        audioRecorder = nil
        isRecording = false
        transcribeFile(at: url, noteID: pendingNoteID)
    }

    // MARK: — File-based speech recognition
    private func transcribeFile(at url: URL, noteID: UUID?) {
        guard let noteID else {
            cleanup(url: url); return
        }
        isProcessing = true

        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            Task { @MainActor [weak self] in
                guard let self else { return }

                guard authStatus == .authorized else {
                    self.setTranscript(
                        "⚠ Speech recognition access denied. Enable it in System Settings → Privacy & Security → Speech Recognition.",
                        for: noteID)
                    self.isProcessing = false
                    self.cleanup(url: url)
                    return
                }

                guard let recognizer = SFSpeechRecognizer(locale: Locale.current),
                      recognizer.isAvailable else {
                    self.setTranscript(
                        "⚠ Speech recognizer unavailable on this device or locale.",
                        for: noteID)
                    self.isProcessing = false
                    self.cleanup(url: url)
                    return
                }

                let request = SFSpeechURLRecognitionRequest(url: url)
                request.shouldReportPartialResults = false   // file mode: final only
                // Force on-device processing — no data sent to Apple servers, works offline.
                request.requiresOnDeviceRecognition = true

                recognizer.recognitionTask(with: request) { [weak self] result, error in
                    Task { @MainActor [weak self] in
                        guard let self else { return }

                        if let error {
                            NSLog("[NSAINoteEngine] Recognition error: \(error)")
                            self.setTranscript(
                                "⚠ Recognition failed: \(error.localizedDescription)",
                                for: noteID)
                            self.isProcessing = false
                            self.cleanup(url: url)
                            return
                        }

                        guard let result, result.isFinal else { return }

                        let text = result.bestTranscription.formattedString
                        self.setTranscript(text.isEmpty ? "(no speech detected)" : text, for: noteID)
                        self.isProcessing = false
                        self.pendingNoteID = nil
                        self.currentRecordingURL = nil
                        self.cleanup(url: url)

                        if !text.isEmpty {
                            Task {
                                if let note = self.notes.first(where: { $0.id == noteID }) {
                                    await self.summarize(text: text, template: note.template, noteID: noteID)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: — Helpers
    private func setTranscript(_ text: String, for noteID: UUID) {
        if let idx = notes.firstIndex(where: { $0.id == noteID }) {
            notes[idx].rawTranscript = text
            save()
        }
    }

    private func cleanup(url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: — AI summarization (FIX 4 — unchanged)
    func summarize(text: String, template: NSAINoteTemplate, noteID: UUID) async {
        guard let idx = notes.firstIndex(where: { $0.id == noteID }) else { return }
        guard NSAIEngine.shared.isConfigured else {
            notes[idx].summary = "⚠ No AI key set. Add one in Settings → AI."
            return
        }
        isProcessing = true
        notes[idx].summary = nil
        let summary = await NSAIEngine.shared.summarize(
            text: text, systemPrompt: template.systemPrompt)
        notes[idx].summary = summary
        notes[idx].updatedAt = Date()
        isProcessing = false
        save()
    }

    // MARK: — CRUD (all unchanged)
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
            .filter { !$0.isEmpty }.joined(separator: "\n\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    // MARK: — Persistence (all unchanged)
    private var storeURL: URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NotchSuperior", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
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
