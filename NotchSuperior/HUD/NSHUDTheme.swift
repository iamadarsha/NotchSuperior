// NOTCHSUPERIOR ADDITION -- HUD Theme

import Foundation

enum NSHUDTheme: String, CaseIterable, Codable, Identifiable {
    case liquidGlass
    case minimal
    case oledBlack
    case iOSStyle

    static let storageKey = "NSHUDTheme"

    var id: String { rawValue }

    static var storedTheme: NSHUDTheme {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: storageKey),
                  let theme = NSHUDTheme(rawValue: rawValue) else {
                return .liquidGlass
            }
            return theme
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
        }
    }
}
