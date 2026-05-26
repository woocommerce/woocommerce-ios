import Foundation
import CommonCrypto
import struct Networking.POSStaffMember

/// Verifies an entered PIN against a staff member's PBKDF2-SHA256 hash.
///
/// The server stores PINs as `pbkdf2_sha256(pin, salt, iterations)` and ships the
/// salt + hash base64-encoded under `pin.salt` / `pin.hash` (see `POSStaffMember.PINDetails`).
/// Mobile receives those over `GET /wc-pos/v1/staff` and computes the same digest
/// locally to verify entry — no PIN ever leaves the device.
public struct POSPBKDF2Verifier {

    public init() {}

    /// Verifies the entered PIN against the cached staff member's hash.
    ///
    /// Returns `false` when:
    /// - The member has no PIN configured (`pin == nil`)
    /// - The algorithm is anything other than `pbkdf2-sha256`
    /// - The salt or hash isn't valid base64
    /// - The derived digest does not match the stored hash
    public func verify(pin: String, member: POSStaffMember) -> Bool {
        guard let details = member.pin,
              details.algo == Constants.supportedAlgorithm,
              details.iterations > 0,
              let saltData = Data(base64Encoded: details.salt),
              let expected = Data(base64Encoded: details.hash),
              !expected.isEmpty,
              let derived = derive(pin: pin,
                                   salt: saltData,
                                   iterations: details.iterations,
                                   keyLength: expected.count) else {
            return false
        }
        return constantTimeEquals(derived, expected)
    }

    // MARK: - PBKDF2-SHA256

    private func derive(pin: String, salt: Data, iterations: Int, keyLength: Int) -> Data? {
        guard let pinBytes = pin.data(using: .utf8) else { return nil }
        var derived = Data(count: keyLength)
        let status: Int32 = derived.withUnsafeMutableBytes { derivedBytes -> Int32 in
            guard let derivedPointer = derivedBytes.bindMemory(to: UInt8.self).baseAddress else {
                return Int32(kCCMemoryFailure)
            }
            return pinBytes.withUnsafeBytes { pinPointer -> Int32 in
                salt.withUnsafeBytes { saltPointer -> Int32 in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        pinPointer.bindMemory(to: Int8.self).baseAddress, pinBytes.count,
                        saltPointer.bindMemory(to: UInt8.self).baseAddress, salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedPointer, keyLength
                    )
                }
            }
        }
        return status == kCCSuccess ? derived : nil
    }

    /// Length-padded constant-time comparison to avoid timing oracles.
    private func constantTimeEquals(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var diff: UInt8 = 0
        for index in 0..<lhs.count {
            diff |= lhs[index] ^ rhs[index]
        }
        return diff == 0
    }

    private enum Constants {
        static let supportedAlgorithm = "pbkdf2-sha256"
    }
}
