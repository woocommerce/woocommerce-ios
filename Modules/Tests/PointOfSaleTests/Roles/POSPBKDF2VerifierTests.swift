import Foundation
import Testing
import CommonCrypto
@testable import PointOfSale
import struct Networking.POSStaffMember

@Suite(.timeLimit(.minutes(5)))
struct POSPBKDF2VerifierTests {

    @Test func verify_when_pin_matches_then_returns_true() throws {
        // Given
        let pin = "4242"
        let salt = "0123456789abcdef0123456789abcdef"
        let iterations = 1_000
        let member = POSStaffMember(
            userID: 42,
            displayName: "Mike",
            role: "pos_cashier",
            hasPIN: true,
            pinSalt: salt,
            pinHash: try derivedHexHash(pin: pin, saltHex: salt, iterations: iterations),
            pinIterations: iterations
        )

        // When
        let result = POSPBKDF2Verifier().verify(pin: pin, member: member)

        // Then
        #expect(result == true)
    }

    @Test func verify_when_pin_does_not_match_then_returns_false() throws {
        // Given
        let salt = "00112233445566778899aabbccddeeff"
        let iterations = 1_000
        let member = POSStaffMember(
            userID: 42,
            displayName: "Mike",
            role: "pos_cashier",
            hasPIN: true,
            pinSalt: salt,
            pinHash: try derivedHexHash(pin: "1234", saltHex: salt, iterations: iterations),
            pinIterations: iterations
        )

        // When
        let result = POSPBKDF2Verifier().verify(pin: "9999", member: member)

        // Then
        #expect(result == false)
    }

    @Test func verify_when_member_has_no_PIN_then_returns_false() {
        // Given
        let member = POSStaffMember(
            userID: 1,
            displayName: "Sarah",
            role: "shop_manager",
            hasPIN: false,
            pinSalt: "",
            pinHash: "",
            pinIterations: 0
        )

        // When
        let result = POSPBKDF2Verifier().verify(pin: "1234", member: member)

        // Then
        #expect(result == false)
    }

    @Test func verify_when_salt_is_malformed_hex_then_returns_false() {
        // Given — odd-length hex is invalid
        let member = POSStaffMember(
            userID: 1,
            displayName: "Sarah",
            role: "pos_manager",
            hasPIN: true,
            pinSalt: "ZZZ",
            pinHash: "deadbeef",
            pinIterations: 100
        )

        // When
        let result = POSPBKDF2Verifier().verify(pin: "1234", member: member)

        // Then
        #expect(result == false)
    }

    // MARK: - Test helper

    /// Computes PBKDF2-SHA256(pin, saltHex, iterations) and returns the lower-hex digest.
    /// Mirrors the WC backend's hash format so the verifier sees a real round-trip.
    private func derivedHexHash(pin: String, saltHex: String, iterations: Int, keyLength: Int = 32) throws -> String {
        guard let pinData = pin.data(using: .utf8) else {
            Issue.record("PIN could not be UTF-8 encoded")
            return ""
        }
        let saltBytes = stride(from: 0, to: saltHex.count, by: 2).compactMap { offset -> UInt8? in
            let startIndex = saltHex.index(saltHex.startIndex, offsetBy: offset)
            let endIndex = saltHex.index(startIndex, offsetBy: 2)
            return UInt8(saltHex[startIndex..<endIndex], radix: 16)
        }
        let salt = Data(saltBytes)

        var derived = Data(count: keyLength)
        let status: Int32 = derived.withUnsafeMutableBytes { derivedBytes -> Int32 in
            guard let derivedPointer = derivedBytes.bindMemory(to: UInt8.self).baseAddress else {
                return Int32(kCCMemoryFailure)
            }
            return pinData.withUnsafeBytes { pinPointer -> Int32 in
                salt.withUnsafeBytes { saltPointer -> Int32 in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        pinPointer.bindMemory(to: Int8.self).baseAddress, pinData.count,
                        saltPointer.bindMemory(to: UInt8.self).baseAddress, salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedPointer, keyLength
                    )
                }
            }
        }
        guard status == kCCSuccess else {
            Issue.record("PBKDF2 failed in test helper with status \(status)")
            return ""
        }
        return derived.map { String(format: "%02x", $0) }.joined()
    }
}
