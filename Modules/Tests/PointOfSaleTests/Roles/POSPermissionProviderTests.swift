import Foundation
import Testing
import CommonCrypto
@testable import PointOfSale
import struct Networking.POSStaffMember
import enum Networking.POSAuthError

@Suite(.timeLimit(.minutes(5)))
@MainActor
struct POSPermissionProviderTests {

    // MARK: - Test helpers

    private static let testSalt = "abcdef0123456789abcdef0123456789"
    private static let testIterations = 1_000

    /// Builds a `POSStaffMember` whose `pinHash` matches PBKDF2(pin, testSalt, testIterations).
    private func makeMember(userID: Int64,
                            pin: String,
                            displayName: String = "Mike",
                            role: String = "pos_cashier",
                            hasPIN: Bool = true) -> POSStaffMember {
        POSStaffMember(
            userID: userID,
            displayName: displayName,
            role: role,
            hasPIN: hasPIN,
            pinSalt: hasPIN ? Self.testSalt : "",
            pinHash: hasPIN ? derivedHexHash(pin: pin, saltHex: Self.testSalt, iterations: Self.testIterations) : "",
            pinIterations: hasPIN ? Self.testIterations : 0
        )
    }

    private func makeProvider(initialCache: [POSStaffMember] = [],
                              fetchStub: @escaping () async throws -> [POSStaffMember] = { [] },
                              appAccountUserID: Int64 = 1) -> POSPermissionProvider {
        POSPermissionProvider(
            appAccountUserID: appAccountUserID,
            appAccountDisplayName: "Admin",
            fetchStaffRemote: fetchStub,
            staffCache: InMemoryPOSStaffCache(initial: initialCache),
            rateLimiter: POSLocalRateLimiter() // shares UserDefaults; test resets below
        )
    }

    // MARK: - hasAnyPINs

    @Test func hasAnyPINs_is_false_when_no_cached_staff_has_PIN() {
        // Given
        let sut = makeProvider(initialCache: [
            makeMember(userID: 1, pin: "0000", hasPIN: false),
            makeMember(userID: 2, pin: "0000", hasPIN: false)
        ])

        // Then
        #expect(sut.hasAnyPINs == false)
    }

    @Test func hasAnyPINs_is_true_when_any_cached_staff_has_PIN() {
        // Given
        let sut = makeProvider(initialCache: [makeMember(userID: 1, pin: "1234")])

        // Then
        #expect(sut.hasAnyPINs == true)
    }

    // MARK: - refreshPINStatus

    @Test func refreshPINStatus_updates_cache_and_drops_lock_when_no_PINs_remain() async {
        // Given — pre-locked (simulating "admin removed all PINs while POS was locked")
        UserDefaults.standard.set(true, forKey: POSLockStateKey.isLocked)
        defer { UserDefaults.standard.set(false, forKey: POSLockStateKey.isLocked) }

        let sut = makeProvider(initialCache: [makeMember(userID: 1, pin: "1234")],
                               fetchStub: { [] })

        // When
        await sut.refreshPINStatus()

        // Then
        #expect(sut.staff.isEmpty)
        #expect(sut.isLocked == false)
    }

    @Test func refreshPINStatus_keeps_cache_on_fetch_failure() async {
        // Given
        let cached = [makeMember(userID: 1, pin: "1234")]
        let sut = makeProvider(initialCache: cached,
                               fetchStub: { throw POSAuthError.unknown(code: "boom", message: "network down") })

        // When
        await sut.refreshPINStatus()

        // Then — cache untouched, hasAnyPINs preserved.
        #expect(sut.staff.count == 1)
        #expect(sut.hasAnyPINs == true)
    }

    // MARK: - authenticatePIN

    @Test func authenticatePIN_when_cached_PIN_matches_then_signs_in_with_role_capabilities() async throws {
        // Given — a cached cashier with PIN 4242
        let cashier = makeMember(userID: 42, pin: "4242", displayName: "Mike", role: "pos_cashier")
        let sut = makeProvider(initialCache: [cashier])

        // When
        let signedIn = try await sut.authenticatePIN("4242")

        // Then
        #expect(signedIn.userID == 42)
        #expect(signedIn.role == "pos_cashier")
        // M1 cashier has no capability-gated affordances.
        #expect(signedIn.capabilities.isEmpty)
        #expect(sut.currentOperator?.userID == 42)
        #expect(sut.isLocked == false)
    }

    @Test func authenticatePIN_when_role_is_pos_manager_then_gets_reduced_capability_set() async throws {
        // Given
        let manager = makeMember(userID: 7, pin: "1111", displayName: "Sarah", role: "pos_manager")
        let sut = makeProvider(initialCache: [manager])

        // When
        let signedIn = try await sut.authenticatePIN("1111")

        // Then — manager gets view settings + refunds + coupons; not editPOSSettings.
        #expect(signedIn.capabilities.contains("view_pos_settings"))
        #expect(signedIn.capabilities.contains("refund_shop_orders"))
        #expect(signedIn.capabilities.contains("publish_shop_coupons"))
        #expect(signedIn.capabilities.contains("edit_pos_settings") == false)
    }

    @Test func authenticatePIN_when_role_is_admin_then_gets_full_capability_set() async throws {
        // Given
        let admin = makeMember(userID: 1, pin: "9999", displayName: "Owner", role: "administrator")
        let sut = makeProvider(initialCache: [admin])

        // When
        let signedIn = try await sut.authenticatePIN("9999")

        // Then — admin gets every POSCapability.
        let expected = Set(POSCapability.allCases.map(\.rawValue))
        #expect(signedIn.capabilities == expected)
    }

    @Test func authenticatePIN_when_pin_unknown_then_refetches_and_retries() async throws {
        // Given — cache holds an old PIN; server now has a new staff member with the entered PIN.
        let oldMember = makeMember(userID: 1, pin: "0000")
        let newMember = makeMember(userID: 2, pin: "4242", displayName: "Mike", role: "pos_cashier")

        var fetchCallCount = 0
        let sut = makeProvider(
            initialCache: [oldMember],
            fetchStub: {
                fetchCallCount += 1
                return [oldMember, newMember]
            }
        )

        // When — enter the PIN that's only in the freshly-fetched list.
        let signedIn = try await sut.authenticatePIN("4242")

        // Then — refetch happened exactly once, and the new member signed in.
        #expect(fetchCallCount == 1)
        #expect(signedIn.userID == 2)
        #expect(sut.staff.count == 2)
    }

    @Test func authenticatePIN_when_pin_unknown_and_refetch_yields_no_match_then_throws_invalidPIN() async {
        // Given
        let cashier = makeMember(userID: 1, pin: "1234")
        let sut = makeProvider(initialCache: [cashier], fetchStub: { [cashier] })

        // When / Then
        await #expect(throws: POSAuthError.self) {
            try await sut.authenticatePIN("9999")
        }
        #expect(sut.currentOperator == nil)
    }

    // MARK: - PBKDF2 helper

    private func derivedHexHash(pin: String, saltHex: String, iterations: Int, keyLength: Int = 32) -> String {
        guard let pinData = pin.data(using: .utf8) else { return "" }
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
        return status == kCCSuccess ? derived.map { String(format: "%02x", $0) }.joined() : ""
    }
}
