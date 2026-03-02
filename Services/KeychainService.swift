import Foundation
import Security

actor KeychainService {
    static let shared = KeychainService()

    enum Key: String, CaseIterable {
        case openAIKey = "com.alexandra767.aegis.openai-key"
        case anthropicKey = "com.alexandra767.aegis.anthropic-key"
        case geminiKey = "com.alexandra767.aegis.gemini-key"
        case groqKey = "com.alexandra767.aegis.groq-key"
        case elevenLabsKey = "com.alexandra767.aegis.elevenlabs-key"
        case customServerURL = "com.alexandra767.aegis.server-url"
        case customServerToken = "com.alexandra767.aegis.server-token"
    }

    enum KeychainError: Error, LocalizedError {
        case saveFailed(OSStatus)
        case deleteFailed(OSStatus)
        case unexpectedData

        var errorDescription: String? {
            switch self {
            case .saveFailed(let status): "Keychain save failed: \(status)"
            case .deleteFailed(let status): "Keychain delete failed: \(status)"
            case .unexpectedData: "Unexpected keychain data format"
            }
        }
    }

    func save(_ value: String, for key: Key) throws {
        guard let data = value.data(using: .utf8) else { return }

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func retrieve(for key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func delete(for key: Key) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    /// Returns a masked preview of the stored key (e.g., "sk-...4f2a")
    func maskedPreview(for key: Key) -> String? {
        guard let value = retrieve(for: key), value.count > 8 else {
            return nil
        }
        let prefix = String(value.prefix(3))
        let suffix = String(value.suffix(4))
        return "\(prefix)...\(suffix)"
    }

    /// Check if a key exists without retrieving its value
    func hasKey(for key: Key) -> Bool {
        retrieve(for: key) != nil
    }
}
