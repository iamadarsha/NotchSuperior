// NOTCHSUPERIOR ADDITION
import SwiftUI

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
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
                        let transcript = engine.stopRecording()
                        note.rawTranscript = transcript
                        engine.updateNote(note)
                    } else {
                        engine.startRecording()
                    }
                }) {
                    Label(engine.isRecording ? "Stop Recording" : "Record Voice",
                          systemImage: engine.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .foregroundStyle(engine.isRecording ? .red : .primary)
                }
                .buttonStyle(.borderless)

                if engine.isRecording {
                    Text(engine.liveTranscript.isEmpty ? "Listening…" : engine.liveTranscript)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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
    }
}
