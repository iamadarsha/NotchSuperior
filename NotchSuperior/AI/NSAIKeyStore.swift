// NOTCHSUPERIOR ADDITION
import Foundation
import Security

final class NSAIKeyStore {
    static let shared = NSAIKeyStore()
    private init() {}

    private func service(for provider: NSAIProvider) -> String {
        "com.notchsuperior.apikey.\(provider.rawValue)"
    }

    func save(key: String, for provider: NSAIProvider) {
        let service = service(for: provider)
        let account = "apikey"
        let data = key.data(using: .utf8)!

        // Delete any existing entry first
        let deleteQuery: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     service,
            kSecAttrAccount as String:     account,
            kSecValueData as String:       data,
            kSecAttrAccessible as String:  kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func load(for provider: NSAIProvider) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service(for: provider),
            kSecAttrAccount as String: "apikey",
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else { return nil }
        return key
    }

    func delete(for provider: NSAIProvider) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service(for: provider),
            kSecAttrAccount as String: "apikey"
        ]
        SecItemDelete(query as CFDictionary)
    }

    func hasKey(for provider: NSAIProvider) -> Bool {
        load(for: provider) != nil
    }
}
