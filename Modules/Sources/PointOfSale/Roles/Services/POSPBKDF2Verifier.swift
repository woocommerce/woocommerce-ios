import Foundation
import CommonCrypto
import struct Networking.POSStaffMember

/// Verifies an entered PIN against a staff member's PBKDF2-SHA256 hash.
///
/// The server stores PINs as `pbkdf2_sha256(pin, salt, iterations)`. Mobile receives
/// `pinSalt`, `pinHash`, and `pinIterations` over `GET /wc-pos/v1/staff` and computes
/// the same digest locally to verify entry — no PIN ever leaves the device.
///
/// Hex-encoded inputs are expected (matching the WooCommerce backend's
/// canonical encoding for password hashes).
public struct POSPBKDF2Verifier {

    public init() {}

    /// Verifies the entered PIN against the cached staff member's hash.
    ///
    /// Returns `false` when:
    /// - The member has no PIN configured (`hasPIN == false`)
    /// - The salt/hash/iterations are empty or malformed
    /// - The derived digest does not match the stored hash
    public func verify(pin: String, member: POSStaffMember) -> Bool {
        guard member.hasPIN,
              !member.pinSalt.isEmpty,
              !member.pinHash.isEmpty,
              member.pinIterations > 0,
              let saltData = Data(hexEncoded: member.pinSalt),
              let expected = Data(hexEncoded: member.pinHash),
              let derived = derive(pin: pin,
                                   salt: saltData,
                                   iterations: member.pinIterations,
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
}

// MARK: - Hex decoding

private extension Data {
    /// Decodes a hex-encoded string into the corresponding bytes. Accepts both
    /// upper- and lower-case digits. Returns nil when the string is malformed or odd-length.
    init?(hexEncoded string: String) {
        guard string.count % 2 == 0 else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(string.count / 2)
        var index = string.startIndex
        while index < string.endIndex {
            let next = string.index(index, offsetBy: 2)
            guard let byte = UInt8(string[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        self = Data(bytes)
    }
}
