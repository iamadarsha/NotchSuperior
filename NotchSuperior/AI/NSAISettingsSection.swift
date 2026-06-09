// NOTCHSUPERIOR ADDITION
import SwiftUI

@available(macOS 26.0, *)
struct NSAISettingsSection: View {
    @ObservedObject var engine = NSAIEngine.shared
    @Environment(\.dismiss) var dismiss

    // Temp input states for key entry
    @State private var openAIKey  = ""
    @State private var claudeKey  = ""
    @State private var geminiKey  = ""
    @State private var showKeys   = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Active Provider") {
                    Picker("Provider", selection: $engine.selectedProviderRaw) {
                        ForEach(NSAIProvider.allCases, id:\.rawValue) { p in
                            Text(p.displayName).tag(p.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("API Keys (stored in Keychain)") {
                    Toggle("Show keys", isOn: $showKeys)

                    HStack {
                        Text("OpenAI")
                            .frame(width: 70, alignment: .leading)
                        if showKeys {
                            TextField("sk-…", text: $openAIKey)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("sk-…", text: $openAIKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        Button("Save") {
                            NSAIKeyStore.shared.save(key: openAIKey, for: .openAI)
                            openAIKey = ""
                        }
                        .disabled(openAIKey.isEmpty)
                        .buttonStyle(.bordered).controlSize(.small)

                        if NSAIKeyStore.shared.hasKey(for: .openAI) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Button("Clear") {
                                NSAIKeyStore.shared.delete(for: .openAI)
                            }
                            .buttonStyle(.borderless).controlSize(.small)
                        }
                    }

                    HStack {
                        Text("Claude")
                            .frame(width: 70, alignment: .leading)
                        if showKeys {
                            TextField("sk-ant-…", text: $claudeKey)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("sk-ant-…", text: $claudeKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        Button("Save") {
                            NSAIKeyStore.shared.save(key: claudeKey, for: .claude)
                            claudeKey = ""
                        }
                        .disabled(claudeKey.isEmpty)
                        .buttonStyle(.bordered).controlSize(.small)

                        if NSAIKeyStore.shared.hasKey(for: .claude) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Button("Clear") {
                                NSAIKeyStore.shared.delete(for: .claude)
                            }
                            .buttonStyle(.borderless).controlSize(.small)
                        }
                    }

                    HStack {
                        Text("Gemini")
                            .frame(width: 70, alignment: .leading)
                        if showKeys {
                            TextField("AIzaSy…", text: $geminiKey)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("AIzaSy…", text: $geminiKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        Button("Save") {
                            NSAIKeyStore.shared.save(key: geminiKey, for: .gemini)
                            geminiKey = ""
                        }
                        .disabled(geminiKey.isEmpty)
                        .buttonStyle(.bordered).controlSize(.small)

                        if NSAIKeyStore.shared.hasKey(for: .gemini) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Button("Clear") {
                                NSAIKeyStore.shared.delete(for: .gemini)
                            }
                            .buttonStyle(.borderless).controlSize(.small)
                        }
                    }
                }

                Section {
                    Text("Keys are encrypted and stored in the macOS Keychain. They are never sent anywhere except the respective provider's API endpoint.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("AI Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 420, minHeight: 340)
    }
}
