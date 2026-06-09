// NOTCHSUPERIOR ADDITION -- Live Activity View

import SwiftUI

struct NSLiveActivityView: View {
    @ObservedObject var engine = NSLiveActivityEngine.shared

    var body: some View {
        Group {
            if let activity = engine.currentActivity {
                activity.compactView
            } else {
                EmptyView()
            }
        }
    }
}
