// NOTCHSUPERIOR ADDITION -- DesignSystem

import SwiftUI

enum NSTokens {
    static let notchCornerRadius: CGFloat = 12
    static let notchExpandedRadius: CGFloat = 20
    static let hudCornerRadius: CGFloat = 22
    static let glassBlur: CGFloat = 20
    static let glassOpacity: Double = 0.12
    static let hudShadowOpacity: Double = 0.22
    static let hairlineOpacity: Double = 0.18
    static let progressHeight: CGFloat = 2
    static let animationSpring = Animation.spring(response: 0.38, dampingFraction: 0.72)
    static let subtleSpring = Animation.spring(response: 0.25, dampingFraction: 0.85)
    static let dismissAnimation = Animation.easeOut(duration: 0.18)
}
