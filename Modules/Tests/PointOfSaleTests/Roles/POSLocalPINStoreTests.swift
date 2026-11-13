import Foundation
import Dispatch
import Synchronization
import Testing
@testable import PointOfSale

struct POSLocalPINStoreTests {
    private let storage = InMemoryPOSSecureStorage()

    @Test func test_validatePIN_when_new_or_existing_role_is_valid_then_does_not_write() throws {
        // Given
        let sut = makeSUT()

        // When
        try sut.validatePIN("1234", for: .admin)

        // Then
        #expect(storage.values.isEmpty)
        try sut.setPIN("1234", for: .admin)
        let original = storage.values
        try sut.validatePIN("1234", for: .admin)
        try sut.validatePIN("5678", for: .cashier)
        #expect(storage.values == original)
    }

    @Test(arguments: [POSLocalRole.admin, .cashier])
    func test_validatePIN_when_matching_other_role_then_rejects_without_writing(role: POSLocalRole) throws {
        // Given
        let sut = makeSUT()
        try sut.setPIN("1234", for: .admin)
        try sut.setPIN("5678", for: .cashier)
        let original = storage.values
        let duplicate = role == .admin ? "5678" : "1234"

        // When / Then
        #expect(throws: POSPINStoreError.pinMatchesOtherRole) { try sut.validatePIN(duplicate, for: role) }
        #expect(storage.values == original)
    }

    @Test func test_credentials_when_nothing_is_stored_then_returns_empty_list() throws {
        // Given
        let sut = makeSUT()

        // When
        let credentials = try sut.credentials()

        // Then
        #expect(credentials.isEmpty)
    }

    @Test func test_setPIN_when_admin_and_cashier_are_set_then_credentials_match_each_role() throws {
        // Given
        let sut = makeSUT()

        // When
        try sut.setPIN("1234", for: .admin)
        try sut.setPIN("5678", for: .cashier)

        // Then
        let credentials = try sut.credentials()
        #expect(credentials.map(\.staff) == [POSLocalRole.admin.staff, POSLocalRole.cashier.staff])
        #expect(credentials[0].pinHash.matches("1234"))
        #expect(credentials[1].pinHash.matches("5678"))
    }

    @Test func test_setPIN_when_saved_then_storage_holds_only_the_salted_hash() throws {
        // Given
        let sut = makeSUT()

        // When
        try sut.setPIN("1234", for: .admin)

        // Then
        let stored = try #require(storage.values["pins.123"])
        let json = try #require(try JSONSerialization.jsonObject(with: stored) as? [String: [String: Any]])
        let admin = try #require(json["admin"])
        #expect(Set(json.keys) == ["admin"])
        #expect(Set(admin.keys) == ["algorithm", "iterations", "salt", "hash"])
        #expect(admin["algorithm"] as? String == "pbkdf2-sha256")
        let salt = try #require((admin["salt"] as? String).flatMap { Data(base64Encoded: $0) })
        let hash = try #require((admin["hash"] as? String).flatMap { Data(base64Encoded: $0) })
        #expect(salt.count == POSPINHash.Constants.saltByteCount)
        #expect(hash.count == POSPINHash.Constants.hashByteCount)
        #expect(try JSONDecoder().decode([String: POSPINHash].self, from: stored)["admin"]?.matches("1234") == true)
    }

    @Test func test_setPIN_when_pin_is_changed_then_only_the_new_pin_matches() throws {
        // Given
        let sut = makeSUT()
        try sut.setPIN("1234", for: .admin)

        // When
        try sut.setPIN("4321", for: .admin)

        // Then
        let admin = try #require(try sut.credentials().first)
        #expect(admin.pinHash.matches("4321"))
        #expect(admin.pinHash.matches("1234") == false)
    }

    @Test(arguments: ["123", "12345", "12a4", "", "١٢٣٤"])
    func test_setPIN_when_pin_is_not_four_digits_then_throws_invalidPINFormat(pin: String) {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(throws: POSPINStoreError.invalidPINFormat) {
            try sut.setPIN(pin, for: .admin)
        }
    }

    @Test func test_setPIN_when_cashier_is_set_without_admin_then_throws_adminPINRequired() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(throws: POSPINStoreError.adminPINRequired) {
            try sut.setPIN("5678", for: .cashier)
        }
    }

    @Test func test_setPIN_when_cashier_pin_equals_admin_pin_then_throws_pinMatchesOtherRole() throws {
        // Given
        let sut = makeSUT()
        try sut.setPIN("1234", for: .admin)

        // When / Then
        #expect(throws: POSPINStoreError.pinMatchesOtherRole) {
            try sut.setPIN("1234", for: .cashier)
        }
    }

    @Test func test_setPIN_when_admin_pin_equals_cashier_pin_then_throws_pinMatchesOtherRole() throws {
        // Given
        let sut = makeSUT()
        try sut.setPIN("1234", for: .admin)
        try sut.setPIN("5678", for: .cashier)

        // When / Then
        #expect(throws: POSPINStoreError.pinMatchesOtherRole) {
            try sut.setPIN("5678", for: .admin)
        }
    }

    @Test func test_removePIN_when_admin_is_removed_then_both_pins_are_removed() throws {
        // Given
        let sut = makeSUT()
        try sut.setPIN("1234", for: .admin)
        try sut.setPIN("5678", for: .cashier)

        // When
        try sut.removePIN(for: .admin)

        // Then
        #expect(try sut.credentials().isEmpty)
        #expect(storage.values.isEmpty)
    }

    @Test func test_removePIN_when_cashier_is_removed_then_admin_remains() throws {
        // Given
        let sut = makeSUT()
        try sut.setPIN("1234", for: .admin)
        try sut.setPIN("5678", for: .cashier)

        // When
        try sut.removePIN(for: .cashier)

        // Then
        #expect(try sut.credentials().map(\.staff) == [POSLocalRole.admin.staff])
    }

    @Test func test_credentials_when_only_a_cashier_pin_is_stored_then_returns_empty_list() throws {
        // Given a Cashier PIN left without an Admin PIN
        let hash = try #require(POSPINHash(pin: "5678", iterations: 1))
        try storage.setData(JSONEncoder().encode(["cashier": hash]), forKey: "pins.123")
        let sut = makeSUT()

        // When
        let credentials = try sut.credentials()

        // Then
        #expect(credentials.isEmpty)
    }

    @Test func test_credentials_when_storage_fails_then_throws_storageFailure() {
        // Given
        storage.shouldFail = true
        let sut = makeSUT()

        // When / Then
        #expect(throws: POSPINStoreError.storageFailure) {
            _ = try sut.credentials()
        }
    }

    @Test func test_credentials_when_stored_data_is_corrupted_then_throws_storageFailure() throws {
        // Given
        try storage.setData(Data("not json".utf8), forKey: "pins.123")
        let sut = makeSUT()

        // When / Then
        #expect(throws: POSPINStoreError.storageFailure) {
            _ = try sut.credentials()
        }
    }

    @Test func test_setPIN_when_storage_fails_then_throws_storageFailure() {
        // Given
        storage.shouldFail = true
        let sut = makeSUT()

        // When / Then
        #expect(throws: POSPINStoreError.storageFailure) {
            try sut.setPIN("1234", for: .admin)
        }
    }

    @Test func test_setPIN_when_set_for_one_site_then_other_site_has_no_pins() throws {
        // Given
        let sut = makeSUT(siteID: 123)
        let otherSite = makeSUT(siteID: 456)

        // When
        try sut.setPIN("1234", for: .admin)

        // Then
        #expect(try otherSite.credentials().isEmpty)
    }

    @Test func test_removeAll_when_several_sites_have_pins_then_removes_every_site() throws {
        // Given
        try makeSUT(siteID: 123).setPIN("1234", for: .admin)
        try makeSUT(siteID: 456).setPIN("1234", for: .admin)

        // When
        try POSLocalPINStore.removeAll(storage: storage)

        // Then
        #expect(try makeSUT(siteID: 123).credentials().isEmpty)
        #expect(try makeSUT(siteID: 456).credentials().isEmpty)
    }

    @Test(arguments: ["set", "removeAdmin", "removeCashier"])
    func test_retired_store_when_logout_has_completed_then_cannot_change_new_credentials(operation: String) throws {
        // Given
        let retired = makeSUT()
        try retired.setPIN("1234", for: .admin)
        try POSPINAttemptContext.clearAll(scopeID: storage.scopeID) { try storage.removeAll() }
        let current = makeSUT()
        try current.setPIN("2468", for: .admin)
        let before = storage.values

        // When / Then
        #expect(throws: POSPINStoreError.storageFailure) {
            switch operation {
            case "set": try retired.setPIN("1357", for: .admin)
            case "removeAdmin": try retired.removePIN(for: .admin)
            default: try retired.removePIN(for: .cashier)
            }
        }
        #expect(storage.values == before)
        #expect(try current.credentials().first?.pinHash.matches("2468") == true)
    }

    @MainActor
    @Test func test_logout_when_pin_write_has_entered_then_clear_completes_last() async throws {
        // Given
        let storage = BlockingPINWriteStorage()
        let store = POSLocalPINStore(siteID: 123, storage: storage, iterations: 1)
        let epoch = POSPINAttemptContext.logoutEpoch(scopeID: storage.scopeID)
        let write = Task.detached { try store.setPIN("1234", for: .admin) }
        defer { storage.releaseWrite() }
        // When
        do {
            let _: Void = try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global().async {
                    guard storage.waitUntilWriteEntered() else {
                        storage.releaseWrite()
                        continuation.resume(throwing: PINWriteRaceFailure.writeDidNotEnter)
                        return
                    }
                    let result = Mutex<Result<Void, POSPINStoreError>?>(nil)
                    let finished = DispatchSemaphore(value: 0)
                    DispatchQueue.global().async {
                        do {
                            try POSPINAttemptContext.clearAll(scopeID: storage.scopeID) { try storage.removeAll() }
                            result.withLock { $0 = .success(()) }
                        } catch {
                            result.withLock { $0 = .failure(.storageFailure) }
                        }
                        finished.signal()
                    }
                    // Other tests can synchronously wait on writes from MainActor. Release from an independent executor.
                    let deadline = ContinuousClock.now.advanced(by: .seconds(2))
                    while POSPINAttemptContext.logoutEpoch(scopeID: storage.scopeID) == epoch, ContinuousClock.now < deadline {
                        Thread.sleep(forTimeInterval: 0.001)
                    }
                    let invalidated = POSPINAttemptContext.logoutEpoch(scopeID: storage.scopeID) != epoch
                    storage.releaseWrite()
                    guard finished.wait(timeout: .now() + 2) == .success else {
                        continuation.resume(throwing: PINWriteRaceFailure.clearDidNotFinish)
                        return
                    }
                    guard invalidated else {
                        continuation.resume(throwing: PINWriteRaceFailure.logoutDidNotInvalidate)
                        return
                    }
                    continuation.resume(with: result.withLock { $0 ?? .failure(.storageFailure) }.mapError { $0 as Error })
                }
            }
        } catch {
            storage.releaseWrite()
            _ = await write.result
            throw error
        }
        try await write.value

        // Then
        #expect(try storage.data(forKey: "pins.123") == nil)
    }
}

private final class BlockingPINWriteStorage: POSSecureStorage, Sendable {
    private let storage = InMemoryPOSSecureStorage()
    private let entered = DispatchSemaphore(value: 0)
    private let release = DispatchSemaphore(value: 0)
    var scopeID: String { storage.scopeID }

    func data(forKey key: String) throws -> Data? { try storage.data(forKey: key) }
    func removeAll() throws { try storage.removeAll() }

    func setData(_ data: Data?, forKey key: String) throws {
        entered.signal()
        guard release.wait(timeout: .now() + 5) == .success else { throw POSPINStoreError.storageFailure }
        try storage.setData(data, forKey: key)
    }

    func waitUntilWriteEntered() -> Bool { entered.wait(timeout: .now() + 2) == .success }

    func releaseWrite() { release.signal() }
}

private enum PINWriteRaceFailure: Error {
    case writeDidNotEnter
    case logoutDidNotInvalidate
    case clearDidNotFinish
}

private extension POSLocalPINStoreTests {
    func makeSUT(siteID: Int64 = 123) -> POSLocalPINStore {
        POSLocalPINStore(siteID: siteID, storage: storage, iterations: 1)
    }
}
