import CommonCrypto
import Foundation
import Security

/// A salted PBKDF2-HMAC-SHA256 hash of a PIN.
struct POSPINHash: Codable, Equatable, Sendable {
    let algorithm: String
    let iterations: Int
    let salt: Data
    let hash: Data

    init(algorithm: String, iterations: Int, salt: Data, hash: Data) {
        self.algorithm = algorithm
        self.iterations = iterations
        self.salt = salt
        self.hash = hash
    }

    /// Hashes `pin` with a new random salt. Returns `nil` if the system can't generate a salt.
    init?(pin: String, iterations: Int = Constants.defaultIterations) {
        var salt = Data(count: Constants.saltByteCount)
        let status = salt.withUnsafeMutableBytes { bytes -> OSStatus in
            guard let baseAddress = bytes.baseAddress else { return errSecAllocate }
            return SecRandomCopyBytes(kSecRandomDefault, Constants.saltByteCount, baseAddress)
        }
        guard status == errSecSuccess,
              let hash = Self.derive(pin: pin, salt: salt, iterations: iterations, byteCount: Constants.hashByteCount) else {
            return nil
        }
        self.init(algorithm: Constants.algorithm, iterations: iterations, salt: salt, hash: hash)
    }

    func matches(_ pin: String) -> Bool {
        // An empty hash would match any PIN; an oversized hash or iteration count would stall PBKDF2.
        guard algorithm == Constants.algorithm,
              !hash.isEmpty,
              hash.count <= Constants.maxHashByteCount,
              iterations <= Constants.maxIterations,
              let derived = Self.derive(pin: pin, salt: salt, iterations: iterations, byteCount: hash.count) else {
            return false
        }
        return Self.constantTimeEqual(derived, hash)
    }
}

private extension POSPINHash {
    static func derive(pin: String, salt: Data, iterations: Int, byteCount: Int) -> Data? {
        guard let rounds = UInt32(exactly: iterations), rounds > 0 else {
            return nil
        }
        let pinData = Data(pin.utf8)
        var derived = [UInt8](repeating: 0, count: byteCount)
        let status = salt.withUnsafeBytes { saltBytes -> Int32 in
            pinData.withUnsafeBytes { pinBytes -> Int32 in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    pinBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                    pinData.count,
                    saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    rounds,
                    &derived,
                    byteCount
                )
            }
        }
        return status == kCCSuccess ? Data(derived) : nil
    }

    static func constantTimeEqual(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        var result: UInt8 = 0
        for (x, y) in zip(a, b) {
            result |= x ^ y
        }
        return result == 0
    }
}

extension POSPINHash {
    enum Constants {
        static let algorithm = "pbkdf2-sha256"
        /// A 4-digit PIN has 10,000 values, so iterations can't stop an offline guess of a copied hash.
        /// They only slow it down; this count keeps a device unlock well under a second.
        static let defaultIterations = 100_000
        static let saltByteCount = 16
        static let hashByteCount = 32
        static let maxHashByteCount = 64
        static let maxIterations = 1_000_000
    }
}
