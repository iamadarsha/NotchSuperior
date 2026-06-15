//
//  TabSelectionView.swift
//  boringNotch
//
//  Created by Hugo Persson on 2024-08-25.
//

import SwiftUI

struct TabModel: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let view: NotchViews
}

let tabs: [TabModel] = {
    var list = [
        TabModel(label: "Home",      icon: "house.fill",         view: .home),
        TabModel(label: "Shelf",     icon: "tray.fill",          view: .shelf)
    ]
    if #available(macOS 14.0, *) {
        list.append(TabModel(label: "Clipboard", icon: "doc.on.clipboard",  view: .clipboard))
        list.append(TabModel(label: "Notes",     icon: "mic.fill",           view: .notes))
        list.append(TabModel(label: "Stats",     icon: "chart.bar.fill",     view: .stats))
        list.append(TabModel(label: "Camera",    icon: "camera.fill",        view: .camera))
    }
    return list
}()

struct TabSelectionView: View {
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @Namespace var animation
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                    TabButton(label: tab.label, icon: tab.icon, selected: coordinator.currentView == tab.view) {
                        withAnimation(.smooth) {
                            coordinator.currentView = tab.view
                        }
                    }
                    .frame(height: 26)
                    .foregroundStyle(tab.view == coordinator.currentView ? .white : .gray)
                    .background {
                        if tab.view == coordinator.currentView {
                            Capsule()
                                .fill(coordinator.currentView == tab.view ? Color(nsColor: .secondarySystemFill) : Color.clear)
                                .matchedGeometryEffect(id: "capsule", in: animation)
                        } else {
                            Capsule()
                                .fill(coordinator.currentView == tab.view ? Color(nsColor: .secondarySystemFill) : Color.clear)
                                .matchedGeometryEffect(id: "capsule", in: animation)
                                .hidden()
                        }
                    }
            }
        }
        .clipShape(Capsule())
    }
}

#Preview {
    BoringHeader().environmentObject(BoringViewModel())
}
