import Foundation
import Testing
import CommonCrypto
@testable import PointOfSale
import struct Networking.POSStaffMember

@Suite(.timeLimit(.minutes(5)))
struct POSPBKDF2VerifierTests {

    @Test func verify_when_pin_matches_then_returns_true() throws {
        // Given — derive the hash the same way the server would, then encode it base64.
        let pin = "4242"
        let saltData = Data(repeating: 0xAB, count: 16)
        let iterations = 1_000
        let hash = try derive(pin: pin, salt: saltData, iterations: iterations)
        let member = POSStaffMember(
            userID: 42,
            displayName: "Mike",
            role: "pos_cashier",
            pin: .init(
                algo: "pbkdf2-sha256",
                iterations: iterations,
                salt: saltData.base64EncodedString(),
                hash: hash.base64EncodedString()
            )
        )

        // When
        let result = POSPBKDF2Verifier().verify(pin: pin, member: member)

        // Then
        #expect(result == true)
    }

    @Test func verify_when_pin_does_not_match_then_returns_false() throws {
        // Given
        let saltData = Data(repeating: 0xCD, count: 16)
        let iterations = 1_000
        let hash = try derive(pin: "1234", salt: saltData, iterations: iterations)
        let member = POSStaffMember(
            userID: 42,
            displayName: "Mike",
            role: "pos_cashier",
            pin: .init(
                algo: "pbkdf2-sha256",
                iterations: iterations,
                salt: saltData.base64EncodedString(),
                hash: hash.base64EncodedString()
            )
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
            pin: nil
        )

        // When
        let result = POSPBKDF2Verifier().verify(pin: "1234", member: member)

        // Then
        #expect(result == false)
    }

    @Test func verify_when_algorithm_is_unsupported_then_returns_false() {
        // Given
        let member = POSStaffMember(
            userID: 1,
            displayName: "Sarah",
            role: "pos_manager",
            pin: .init(
                algo: "argon2id",
                iterations: 1_000,
                salt: Data(repeating: 0x00, count: 16).base64EncodedString(),
                hash: Data(repeating: 0xFF, count: 32).base64EncodedString()
            )
        )

        // When
        let result = POSPBKDF2Verifier().verify(pin: "1234", member: member)

        // Then
        #expect(result == false)
    }

    @Test func verify_when_salt_is_invalid_base64_then_returns_false() {
        // Given — base64 strings must be multiples of 4 chars; "ZZZ" is not.
        let member = POSStaffMember(
            userID: 1,
            displayName: "Sarah",
            role: "pos_manager",
            pin: .init(
                algo: "pbkdf2-sha256",
                iterations: 1_000,
                salt: "ZZZ",
                hash: Data(repeating: 0xFF, count: 32).base64EncodedString()
            )
        )

        // When
        let result = POSPBKDF2Verifier().verify(pin: "1234", member: member)

        // Then
        #expect(result == false)
    }

    // MARK: - Test helper

    /// Performs PBKDF2-SHA256 in the same shape the server does so tests can
    /// round-trip a real hash through the verifier.
    private func derive(pin: String, salt: Data, iterations: Int, keyLength: Int = 32) throws -> Data {
        guard let pinData = pin.data(using: .utf8) else {
            Issue.record("PIN could not be UTF-8 encoded")
            return Data()
        }
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
            return Data()
        }
        return derived
    }
}
