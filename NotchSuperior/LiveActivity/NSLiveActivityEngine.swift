// NOTCHSUPERIOR ADDITION -- Live Activity Engine

import SwiftUI

protocol NSActivity {
    var id: UUID { get }
    var priority: Int { get }
    var compactView: AnyView { get }
    var expandedView: AnyView { get }
    var ttl: TimeInterval? { get }
}

@MainActor
final class NSLiveActivityEngine: ObservableObject {
    static let shared = NSLiveActivityEngine()

    @Published var currentActivity: (any NSActivity)?

    private init() {}
}
