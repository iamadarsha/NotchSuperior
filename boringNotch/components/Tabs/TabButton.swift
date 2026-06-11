//
//  TabButton.swift
//  boringNotch
//
//  Created by Hugo Persson on 2024-08-24.
//

import SwiftUI

struct TabButton: View {
    let label: String
    let icon: String
    let selected: Bool
    let onClick: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: onClick) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: selected ? .semibold : .medium))
                .padding(.horizontal, 15)
                .padding(.vertical, 6)
                .contentShape(Capsule())
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.interpolatingSpring(stiffness: 300, damping: 15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    TabButton(label: "Home", icon: "tray.fill", selected: true) {
        print("Tapped")
    }
}
