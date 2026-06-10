// NOTCHSUPERIOR ADDITION
import SwiftUI

@available(macOS 14.0, *)
struct NSCommandLauncherView: View {
    @ObservedObject var engine = NSCommandEngine.shared
    @State private var textInput = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search Input Row
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField("Search commands or type shell script...", text: $textInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .regular))
                    .focused($isTextFieldFocused)
                    .onChange(of: textInput) { _, newValue in
                        engine.search(newValue)
                    }
                    .onSubmit {
                        Task {
                            await engine.executeSelected()
                        }
                    }
                
                if engine.isRunning {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            
            if !engine.results.isEmpty {
                Divider()
                
                // Results List
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(0..<engine.results.count, id: \.self) { idx in
                                let item = engine.results[idx]
                                HStack(spacing: 10) {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 14))
                                        .frame(width: 20)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.system(size: 12, weight: .medium))
                                        if let subtitle = item.subtitle {
                                            Text(subtitle)
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if idx == engine.selectedIndex {
                                        Image(systemName: "return")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 38)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(idx == engine.selectedIndex ? Color.blue.opacity(0.15) : Color.clear)
                                )
                                .id(idx)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    engine.selectedIndex = idx
                                    Task {
                                        await engine.executeSelected()
                                    }
                                }
                            }
                        }
                        .padding(6)
                    }
                    .frame(maxHeight: 200)
                    .onChange(of: engine.selectedIndex) { _, newIndex in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
            engine.search("")
        }
        .onDisappear {
            textInput = ""
        }
        // Handle keyboard navigation directly on the view
        .onKeyPress(.upArrow) {
            engine.selectPrev()
            return .handled
        }
        .onKeyPress(.downArrow) {
            engine.selectNext()
            return .handled
        }
        .onKeyPress(.escape) {
            engine.hide()
            return .handled
        }
    }
}
