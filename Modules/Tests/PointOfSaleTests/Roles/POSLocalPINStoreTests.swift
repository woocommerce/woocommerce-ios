import Foundation
import Testing
@testable import PointOfSale

struct POSLocalPINStoreTests {
    private let storage = InMemoryPOSSecureStorage()

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
        #expect(credentials.map(\.staff) == [POSStaff(role: .admin), POSStaff(role: .cashier)])
        #expect(credentials[0].pinHash.matches("1234"))
        #expect(credentials[1].pinHash.matches("5678"))
    }

    @Test func test_setPIN_when_saved_then_storage_does_not_contain_the_plain_pin() throws {
        // Given
        let sut = makeSUT()

        // When
        try sut.setPIN("1234", for: .admin)

        // Then
        let stored = try #require(storage.values["pins.123"])
        #expect(String(decoding: stored, as: UTF8.self).contains("1234") == false)
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
        #expect(try sut.credentials().map(\.staff.role) == [.admin])
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
}

private extension POSLocalPINStoreTests {
    func makeSUT(siteID: Int64 = 123) -> POSLocalPINStore {
        POSLocalPINStore(siteID: siteID, storage: storage, iterations: 1)
    }
}
