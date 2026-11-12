import Foundation
import Testing
@testable import PointOfSale

@MainActor
struct POSRolesPersistenceTests {
    @Test func test_clearAll_removes_local_pins_for_every_site() throws {
        // Given
        let storage = InMemoryPOSSecureStorage()
        try POSLocalPINStore(siteID: 123, storage: storage, iterations: 1).setPIN("1234", for: .admin)
        try POSLocalPINStore(siteID: 456, storage: storage, iterations: 1).setPIN("1234", for: .admin)

        // When
        try POSRolesPersistence.clearAll(pinStorage: storage, userDefaults: UserDefaultsTestScope().defaults)

        // Then
        #expect(try POSLocalPINStore(siteID: 123, storage: storage).credentials().isEmpty)
        #expect(try POSLocalPINStore(siteID: 456, storage: storage).credentials().isEmpty)
    }

    @Test func test_clearAll_clears_lock_flags_for_every_site() throws {
        // Given lock flags persisted for several sites
        let scope = UserDefaultsTestScope()
        scope.defaults.set(true, forKey: POSLockStateKey.key(for: 123))
        scope.defaults.set(true, forKey: POSLockStateKey.key(for: 456))

        // When
        try POSRolesPersistence.clearAll(pinStorage: InMemoryPOSSecureStorage(), userDefaults: scope.defaults)

        // Then no site's lock flag reads as locked
        #expect(scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == false)
        #expect(scope.defaults.bool(forKey: POSLockStateKey.key(for: 456)) == false)
    }

    @Test func test_clearAll_leaves_unrelated_user_defaults_keys_untouched() throws {
        // Given a POS lock flag alongside an unrelated app preference
        let scope = UserDefaultsTestScope()
        scope.defaults.set(true, forKey: POSLockStateKey.key(for: 123))
        scope.defaults.set("keep", forKey: "com.woocommerce.someOtherSetting")

        // When
        try POSRolesPersistence.clearAll(pinStorage: InMemoryPOSSecureStorage(), userDefaults: scope.defaults)

        // Then the lock-state prefix scan removes only the POS lock flag
        #expect(scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == false)
        #expect(scope.defaults.string(forKey: "com.woocommerce.someOtherSetting") == "keep")
    }
}

extension POSRolesPersistenceTests {
    @Test func test_clearAll_when_pin_removal_fails_then_throws_and_still_clears_lock_flags() {
        // Given
        let scope = UserDefaultsTestScope()
        scope.defaults.set(true, forKey: POSLockStateKey.key(for: 123))
        let storage = InMemoryPOSSecureStorage()
        storage.shouldFail = true

        // When / Then
        #expect(throws: (any Error).self) {
            try POSRolesPersistence.clearAll(pinStorage: storage, userDefaults: scope.defaults)
        }
        #expect(scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == false)
    }
}

private final class UserDefaultsTestScope {
    let defaults: UserDefaults
    private let suiteName: String

    init() {
        suiteName = "test.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
