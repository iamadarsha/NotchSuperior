// NOTCHSUPERIOR ADDITION
import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// NSAINotesView — Settings pane for voice notes.
//
// Uses HSplitView (NOT NavigationSplitView) because this view is already
// embedded inside SettingsView's own NavigationSplitView.  Nesting two
// NavigationSplitViews causes the left sidebar to collapse and become invisible.
// ─────────────────────────────────────────────────────────────────────────────

@available(macOS 14.0, *)
struct NSAINotesView: View {
    @ObservedObject var engine = NSAINoteEngine.shared
    @State private var selectedNoteID: UUID? = nil

    var body: some View {
        HSplitView {
            notesList
            detailPane
        }
        .frame(minWidth: 560, minHeight: 400)
        .navigationTitle("Voice Notes")
        .onAppear {
            if selectedNoteID == nil {
                selectedNoteID = engine.notes.first?.id
            }
        }
        .onChange(of: engine.notes) { _, newNotes in
            if selectedNoteID == nil ||
               !newNotes.contains(where: { $0.id == selectedNoteID }) {
                selectedNoteID = newNotes.first?.id
            }
        }
    }

    // MARK: — Left column: notes list

    private var notesList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Voice Notes")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button(action: createAndSelectNote) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderless)
                .help("New voice note")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // On-device badge
            HStack(spacing: 5) {
                Image(systemName: "cpu")
                    .font(.system(size: 9))
                Text("On-Device Transcription · No API key needed")
                    .font(.system(size: 9))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            Divider()

            if engine.notes.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "mic.circle")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("No voice notes yet")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Button("Record First Note", action: createAndSelectNote)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List(engine.notes, selection: $selectedNoteID) { note in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(note.title)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            if note.summary != nil {
                                Image(systemName: "text.bubble.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.blue.opacity(0.7))
                            } else if note.rawTranscript != nil {
                                Image(systemName: "waveform")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.green.opacity(0.7))
                            }
                            Text(note.updatedAt, style: .relative)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(note.id)
                    .contextMenu {
                        Button("Export to Clipboard") { engine.exportNote(note) }
                        Divider()
                        Button("Delete", role: .destructive) {
                            engine.deleteNote(note.id)
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .frame(minWidth: 190, idealWidth: 210, maxWidth: 250)
        .background(.background)
    }

    // MARK: — Right column: detail pane

    @ViewBuilder
    private var detailPane: some View {
        if let id = selectedNoteID,
           let note = engine.notes.first(where: { $0.id == id }) {
            NSAINoteDetailView(note: note)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "mic.badge.plus")
                    .font(.system(size: 40))
                    .foregroundStyle(.tertiary)
                Text("Select a note or create a new one")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Button("New Voice Note", action: createAndSelectNote)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: — Helpers

    private func createAndSelectNote() {
        let n = engine.createNote(
            title: "Note \(Date().formatted(.dateTime.month().day().hour().minute()))")
        selectedNoteID = n.id
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// NSAINoteDetailView — Right-pane note editor with recording + AI summary
// ─────────────────────────────────────────────────────────────────────────────

@available(macOS 14.0, *)
struct NSAINoteDetailView: View {
    @State var note: NSAINote
    @ObservedObject var engine = NSAINoteEngine.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                // Title
                TextField("Note title", text: $note.title)
                    .font(.system(size: 16, weight: .semibold))
                    .textFieldStyle(.plain)
                    .onChange(of: note.title) { _, _ in engine.updateNote(note) }

                // Template picker
                HStack {
                    Text("Template:")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Picker("", selection: $note.template) {
                        ForEach(NSAINoteTemplate.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .frame(maxWidth: 160)
                    Spacer()
                }

                Divider()

                // ── Recording controls ──
                recordingSection

                Divider()

                // ── Transcript ──
                transcriptSection

                // ── Summary ──
                if let summary = note.summary, !summary.isEmpty {
                    summarySection(summary)
                }
            }
            .padding(18)
        }
        // Refresh local @State when async transcript lands in engine.notes.
        .onChange(of: engine.notes) { _, _ in
            if let updated = engine.notes.first(where: { $0.id == note.id }) {
                note = updated
            }
        }
    }

    // MARK: — Recording section

    private var recordingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Recording", systemImage: "waveform.circle")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                // Record / Stop button
                Button(action: toggleRecording) {
                    HStack(spacing: 6) {
                        Image(systemName: engine.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 12))
                        Text(engine.isRecording ? "Stop Recording" : "Record")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(engine.isRecording ? .red : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(engine.isRecording ? Color.red.opacity(0.15) : Color.accentColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(engine.isRecording ? Color.red : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Status
                if engine.isRecording {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("Listening…")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                } else if engine.isProcessing {
                    HStack(spacing: 5) {
                        ProgressView().scaleEffect(0.6)
                        Text("Transcribing on-device…")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                } else if note.rawTranscript != nil {
                    Label("Transcribed", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                }

                Spacer()

                // On-device badge
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .font(.system(size: 9))
                    Text("On-Device")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(Color.secondary.opacity(0.1))
                )
            }

            // Live transcript during recording
            if engine.isRecording && !engine.liveTranscript.isEmpty {
                Text(engine.liveTranscript)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.07)))
            }
        }
    }

    // MARK: — Transcript section

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Transcript", systemImage: "text.alignleft")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            TextEditor(text: Binding(
                get: { note.rawTranscript ?? "" },
                set: { note.rawTranscript = $0; engine.updateNote(note) }
            ))
            .font(.system(size: 12))
            .frame(minHeight: 90)
            .scrollContentBackground(.hidden)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.07))
            )

            // Summarize button
            Button(action: summarize) {
                HStack(spacing: 5) {
                    if engine.isProcessing {
                        ProgressView().scaleEffect(0.6)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                    }
                    Text(engine.isProcessing ? "Summarizing…" : "Summarize with AI")
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(note.rawTranscript?.isEmpty ?? true || engine.isProcessing)
            .help(NSAIEngine.shared.isConfigured
                  ? "Summarize using your configured AI provider"
                  : "Add an API key in Settings → AI → API Keys to enable summarization")
        }
    }

    // MARK: — Summary section

    private func summarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            HStack {
                Label("AI Summary", systemImage: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(summary, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                }
                .buttonStyle(.borderless)
                .help("Copy summary")
            }
            Text(summary)
                .font(.system(size: 12))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.07))
                )
        }
    }

    // MARK: — Helpers

    private func toggleRecording() {
        if engine.isRecording {
            engine.stopRecording()
        } else {
            engine.startRecording(for: note.id)
        }
    }

    private func summarize() {
        Task {
            await engine.summarize(
                text: note.rawTranscript ?? "",
                template: note.template,
                noteID: note.id)
            if let updated = engine.notes.first(where: { $0.id == note.id }) {
                note = updated
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// NSNotchNotesView — Compact notch widget (unchanged layout, minor polish)
// ─────────────────────────────────────────────────────────────────────────────

@available(macOS 14.0, *)
struct NSNotchNotesView: View {
    @ObservedObject var engine = NSAINoteEngine.shared
    @State private var copiedNoteID: UUID? = nil
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 16) {
            // Left Column: Recording Controls
            VStack(spacing: 6) {
                Text(engine.isRecording ? "Recording..." : "Voice Notes")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(engine.isRecording ? .red : .primary)

                Button(action: {
                    HapticHelper.trigger()
                    if engine.isRecording {
                        engine.stopRecording()
                    } else {
                        let title = "Note \(Date().formatted(.dateTime.hour().minute().second()))"
                        let newNote = engine.createNote(title: title, template: .freeform)
                        engine.startRecording(for: newNote.id)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(engine.isRecording ? Color.red.opacity(0.15) : Color.white.opacity(0.08))
                            .frame(width: 44, height: 44)
                            .scaleEffect(engine.isRecording ? (isPulsing ? 1.15 : 1.0) : 1.0)
                            .animation(engine.isRecording
                                ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                                : .default, value: isPulsing)

                        Circle()
                            .fill(engine.isRecording ? Color.red : Color.accentColor)
                            .frame(width: 34, height: 34)

                        Image(systemName: engine.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .onAppear { if engine.isRecording { isPulsing = true } }
                .onChange(of: engine.isRecording) { _, newValue in
                    isPulsing = newValue
                }

                if engine.isRecording || engine.isProcessing {
                    Text(engine.isProcessing ? "Transcribing…" : "Listening…")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(width: 160)
                } else {
                    Button("Manage Notes...") {
                        HapticHelper.trigger()
                        SettingsWindowController.shared.showWindow(tab: "AINotes")
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .font(.system(size: 10))
                }
            }
            .frame(width: 170)

            Divider().padding(.vertical, 4)

            // Right Column: Recent Notes
            VStack(alignment: .leading, spacing: 2) {
                Text("Recent Recordings")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 2)

                if engine.notes.isEmpty {
                    VStack {
                        Spacer()
                        Text("No recordings yet.\nTap mic to start.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(engine.notes.prefix(3)) { note in
                                HStack {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(note.title)
                                            .font(.system(size: 10, weight: .medium))
                                            .lineLimit(1)

                                        if let summary = note.summary {
                                            Text(summary)
                                                .font(.system(size: 9))
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        } else if engine.isProcessing {
                                            Text("Transcribing…")
                                                .font(.system(size: 9))
                                                .foregroundStyle(.blue)
                                        } else {
                                            Text(note.rawTranscript ?? "No transcript")
                                                .font(.system(size: 9))
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer()

                                    Button(action: {
                                        HapticHelper.trigger()
                                        let textToCopy = note.summary ?? note.rawTranscript ?? ""
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(textToCopy, forType: .string)
                                        copiedNoteID = note.id
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            if copiedNoteID == note.id { copiedNoteID = nil }
                                        }
                                    }) {
                                        Image(systemName: copiedNoteID == note.id
                                              ? "checkmark.circle.fill" : "doc.on.doc")
                                            .font(.system(size: 9))
                                            .foregroundStyle(copiedNoteID == note.id ? .green : .secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Copy content")
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(
                                    Color.white.opacity(0.04),
                                    in: RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
