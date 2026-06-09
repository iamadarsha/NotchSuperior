// NOTCHSUPERIOR ADDITION -- Timer Activity

import SwiftUI

struct NSTimerActivity: NSActivity {
    let id = UUID()
    let priority = 1
    let ttl: TimeInterval? = nil

    var compactView: AnyView { AnyView(EmptyView()) }
    var expandedView: AnyView { AnyView(EmptyView()) }
}
