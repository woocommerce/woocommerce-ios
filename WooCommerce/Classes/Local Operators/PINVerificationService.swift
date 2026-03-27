import CryptoKit
import Foundation
import KeychainAccess

enum PINVerificationError: Error {
    case invalidPIN
}

final class PINVerificationService: PINVerificationServiceProtocol {
    private let keychain: Keychain

    init(keychain: Keychain = Keychain(service: WooConstants.keychainServiceName).accessibility(.afterFirstUnlock)) {
        self.keychain = keychain
    }

    func storePIN(_ pin: String, for reference: String) throws {
        let normalizedPIN = pin.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (4...6).contains(normalizedPIN.count), CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: normalizedPIN)) else {
            throw PINVerificationError.invalidPIN
        }

        let salt = randomSalt()
        let hash = Self.hash(pin: normalizedPIN, salt: salt)
        keychain[key(for: reference)] = "\(salt):\(hash)"
    }

    func verifyPIN(_ pin: String, for reference: String) -> Bool {
        guard let storedValue = keychain[key(for: reference)] else {
            return false
        }

        let components = storedValue.components(separatedBy: ":")
        guard components.count == 2 else {
            return false
        }

        let salt = components[0]
        let expectedHash = components[1]
        return Self.hash(pin: pin.trimmingCharacters(in: .whitespacesAndNewlines), salt: salt) == expectedHash
    }

    func deletePIN(for reference: String) {
        keychain[key(for: reference)] = nil
    }
}

private extension PINVerificationService {
    func key(for reference: String) -> String {
        "local_operator_pin_\(reference)"
    }

    func randomSalt() -> String {
        let bytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).map { String(format: "%02x", $0) }.joined()
    }

    static func hash(pin: String, salt: String) -> String {
        SHA256.hash(data: Data((salt + pin).utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

