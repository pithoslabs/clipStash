import Foundation
import CryptoKit
import Security

/// Handles encryption/decryption of clipboard history using AES-GCM with a Keychain-stored key
enum EncryptionHelper {

    private static let keychainService = "com.clipstash.encryption"
    private static let keychainAccount = "history-key"

    // MARK: - Public API

    /// Encrypts data using AES-GCM
    static func encrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        return combined
    }

    /// Decrypts data using AES-GCM
    static func decrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // MARK: - Key Management

    private static func getOrCreateKey() throws -> SymmetricKey {
        if let existingKey = try loadKeyFromKeychain() {
            return existingKey
        }

        let newKey = SymmetricKey(size: .bits256)
        try saveKeyToKeychain(newKey)
        return newKey
    }

    private static func loadKeyFromKeychain() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let keyData = result as? Data else {
                throw EncryptionError.keychainError(status)
            }
            return SymmetricKey(data: keyData)
        case errSecItemNotFound:
            return nil
        default:
            throw EncryptionError.keychainError(status)
        }
    }

    private static func saveKeyToKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess && status != errSecDuplicateItem {
            throw EncryptionError.keychainError(status)
        }
    }

    // MARK: - Errors

    enum EncryptionError: LocalizedError {
        case encryptionFailed
        case decryptionFailed
        case keychainError(OSStatus)

        var errorDescription: String? {
            switch self {
            case .encryptionFailed:
                return "Failed to encrypt data"
            case .decryptionFailed:
                return "Failed to decrypt data"
            case .keychainError(let status):
                return "Keychain error: \(status)"
            }
        }
    }
}
