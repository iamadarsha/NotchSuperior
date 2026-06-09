// NOTCHSUPERIOR ADDITION
import SwiftUI

@available(macOS 26.0, *)
struct NSAIChatView: View {
    @ObservedObject var engine = NSAIEngine.shared
    @State private var inputText = ""
    @State private var selectedConvID: UUID? = nil
    @State private var showSettings = false

    // Active conversation (create one lazily)
    private var activeConv: NSAIConversation? {
        guard let id = selectedConvID else { return nil }
        return engine.conversations.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AI Chat")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                // Provider picker (compact)
                Picker("", selection: $engine.selectedProviderRaw) {
                    ForEach(NSAIProvider.allCases, id:\.rawValue) { p in
                        Text(p.displayName).tag(p.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 130)
                // New chat
                Button(action: {
                    let conv = engine.newConversation()
                    selectedConvID = conv.id
                }) {
                    Image(systemName: "square.and.pencil")
                }
                .buttonStyle(.borderless)
                // Settings
                Button(action: { showSettings = true }) {
                    Image(systemName: "key")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)

            Divider()

            if !engine.isConfigured {
                // No-key state
                VStack(spacing: 8) {
                    Image(systemName: "key.slash")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("No API key set")
                        .font(.system(size: 13, weight: .medium))
                    Text("Add your \(engine.selectedProvider.displayName) key in Settings → AI.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Open Settings") { showSettings = true }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if let conv = activeConv {
                // Message list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(conv.messages) { msg in
                                NSAIMessageBubble(message: msg)
                                    .id(msg.id.uuidString)
                            }
                            if engine.isStreaming {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                    Text("Thinking…")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .id("streaming")
                            }
                        }
                        .padding(8)
                    }
                    .onChange(of: conv.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(conv.messages.last?.id.uuidString ?? "streaming",
                                           anchor: .bottom)
                        }
                    }
                }

                Divider()

                // Input bar
                HStack(spacing: 6) {
                    TextField("Message…", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...4)
                        .font(.system(size: 12))
                        .onSubmit { sendMessage(in: conv.id) }

                    if engine.isStreaming {
                        Button(action: { engine.cancelStream() }) {
                            Image(systemName: "stop.circle.fill")
                                .foregroundStyle(Color.red)
                        }
                        .buttonStyle(.borderless)
                    } else {
                        Button(action: { sendMessage(in: conv.id) }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(inputText.isEmpty ? Color.secondary : Color.blue)
                        }
                        .buttonStyle(.borderless)
                        .disabled(inputText.isEmpty)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 8))
                .padding([.horizontal, .bottom], 8)

            } else {
                // No conversation selected yet
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 28)).foregroundStyle(.secondary)
                    Text("Start a new chat")
                        .font(.system(size: 13, weight: .medium))
                    Button("New Chat") {
                        let conv = engine.newConversation()
                        selectedConvID = conv.id
                    }
                    .buttonStyle(.borderedProminent).controlSize(.small)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showSettings) {
            NSAISettingsSection()
        }
        .onAppear {
            if selectedConvID == nil {
                selectedConvID = engine.conversations.first?.id
            }
        }
    }

    private func sendMessage(in convID: UUID) {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        Task { await engine.sendMessage(text, in: convID) }
    }
}

// Single message bubble
@available(macOS 26.0, *)
struct NSAIMessageBubble: View {
    let message: NSAIChatMessage
    var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .top) {
            if isUser { Spacer(minLength: 40) }
            Text(message.content.isEmpty ? "…" : message.content)
                .font(.system(size: 12))
                .textSelection(.enabled)
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(
                    isUser
                    ? AnyShapeStyle(Color.blue.opacity(0.18))
                    : AnyShapeStyle(.ultraThinMaterial),
                    in: RoundedRectangle(cornerRadius: 12))
            if !isUser { Spacer(minLength: 40) }
        }
    }
}
