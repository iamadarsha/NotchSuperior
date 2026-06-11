// NOTCHSUPERIOR ADDITION
import SwiftUI

@available(macOS 14.0, *)
struct NSAINotesView: View {
    @ObservedObject var engine = NSAINoteEngine.shared
    @State private var selectedNoteID: UUID? = nil

    var body: some View {
        NavigationSplitView {
            // Sidebar: note list
            List(engine.notes, selection: $selectedNoteID) { note in
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.title)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    Text(note.updatedAt, style: .relative)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .tag(note.id)
                .contextMenu {
                    Button("Delete", role:.destructive) {
                        engine.deleteNote(note.id)
                    }
                    Button("Export to Clipboard") {
                        engine.exportNote(note)
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        let n = engine.createNote()
                        selectedNoteID = n.id
                    }) { Image(systemName: "plus") }
                }
            }
        } detail: {
            if let id = selectedNoteID,
               let note = engine.notes.first(where: { $0.id == id }) {
                NSAINoteDetailView(note: note)
            } else {
                Text("Select or create a note")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 520, minHeight: 320)
    }
}

@available(macOS 14.0, *)
struct NSAINoteDetailView: View {
    @State var note: NSAINote
    @ObservedObject var engine = NSAINoteEngine.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            TextField("Note title", text: $note.title)
                .font(.system(size: 14, weight: .semibold))
                .textFieldStyle(.plain)
                .onChange(of: note.title) { _ in engine.updateNote(note) }

            // Template picker
            Picker("Template", selection: $note.template) {
                ForEach(NSAINoteTemplate.allCases, id:\.self) { t in
                    Text(t.displayName).tag(t)
                }
            }
            .pickerStyle(.menu)
            .controlSize(.small)

            Divider()

            // Voice recording button
            HStack {
                Button(action: {
                    if engine.isRecording {
                        // stopRecording() is now void — transcript arrives async
                        // via engine.notes. The .onChange block below refreshes `note`.
                        engine.stopRecording()
                    } else {
                        // Pass noteID so the engine knows which note to update
                        // when SFSpeechURLRecognitionRequest finishes.
                        engine.startRecording(for: note.id)
                    }
                }) {
                    Label(engine.isRecording ? "Stop Recording" : "Record Voice",
                          systemImage: engine.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .foregroundStyle(engine.isRecording ? .red : .primary)
                }
                .buttonStyle(.borderless)

                if engine.isRecording || !engine.liveTranscript.isEmpty {
                    Text(engine.liveTranscript.isEmpty ? "Listening…" : engine.liveTranscript)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Raw transcript text editor
            Text("Transcript / Notes")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            TextEditor(text: Binding(
                get: { note.rawTranscript ?? "" },
                set: { note.rawTranscript = $0; engine.updateNote(note) }
            ))
            .font(.system(size: 12))
            .frame(minHeight: 80)

            // Summarize button
            Button(action: {
                Task {
                    await engine.summarize(
                        text: note.rawTranscript ?? "",
                        template: note.template,
                        noteID: note.id)
                    // Refresh
                    if let updated = engine.notes.first(where:{ $0.id == note.id }) {
                        note = updated
                    }
                }
            }) {
                HStack {
                    if engine.isProcessing {
                        ProgressView().scaleEffect(0.6)
                    }
                    Text(engine.isProcessing ? "Summarizing…" : "Summarize with AI ✦")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(note.rawTranscript?.isEmpty ?? true || engine.isProcessing)

            // Summary output
            if let summary = note.summary, !summary.isEmpty {
                Divider()
                Text("Summary")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(summary)
                    .font(.system(size: 12))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        // Refresh local @State `note` when async transcript lands in engine.notes.
        .onChange(of: engine.notes) { _ in
            if let updated = engine.notes.first(where: { $0.id == note.id }) {
                note = updated
            }
        }
    }
}

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
                        let title = "Voice Note \(Date().formatted(.dateTime.hour().minute().second()))"
                        let newNote = engine.createNote(title: title, template: .freeform)
                        engine.startRecording(for: newNote.id)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(engine.isRecording ? Color.red.opacity(0.15) : Color.white.opacity(0.08))
                            .frame(width: 44, height: 44)
                            .scaleEffect(engine.isRecording ? (isPulsing ? 1.15 : 1.0) : 1.0)
                            .animation(engine.isRecording ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: isPulsing)
                        
                        Circle()
                            .fill(engine.isRecording ? Color.red : Color.accentColor)
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: engine.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .onAppear {
                    if engine.isRecording {
                        isPulsing = true
                    }
                }
                .onChange(of: engine.isRecording) { newValue in
                    isPulsing = newValue
                }
                
                if engine.isRecording || !engine.liveTranscript.isEmpty {
                    Text(engine.liveTranscript.isEmpty ? "Listening..." : engine.liveTranscript)
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
            
            Divider()
                .padding(.vertical, 4)
            
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
                                            Text("Summarizing...")
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
                                            if copiedNoteID == note.id {
                                                copiedNoteID = nil
                                            }
                                        }
                                    }) {
                                        Image(systemName: copiedNoteID == note.id ? "checkmark.circle.fill" : "doc.on.doc")
                                            .font(.system(size: 9))
                                            .foregroundStyle(copiedNoteID == note.id ? .green : .secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Copy content")
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
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
