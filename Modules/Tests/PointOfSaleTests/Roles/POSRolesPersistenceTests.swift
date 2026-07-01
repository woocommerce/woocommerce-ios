import Foundation
import Testing
import struct Yosemite.POSStaffMember
@testable import PointOfSale

@MainActor
struct POSRolesPersistenceTests {
    @Test func test_clearAll_wipes_staff_cache_for_every_site() {
        // Given staff cached with PINs for several sites
        let storage = InMemoryStaffStorage()
        let cache = POSStaffCache(storage: storage)
        cache.save([makeStaffMemberWithPIN()], siteID: 123)
        cache.save([makeStaffMemberWithPIN()], siteID: 456)

        // When
        POSRolesPersistence.clearAll(staffStorage: storage, userDefaults: UserDefaultsTestScope().defaults)

        // Then every site's cached staff is gone
        #expect(cache.load(siteID: 123) == nil)
        #expect(cache.load(siteID: 456) == nil)
    }

    @Test func test_clearAll_clears_lock_flags_for_every_site() {
        // Given lock flags persisted for several sites
        let scope = UserDefaultsTestScope()
        scope.defaults.set(true, forKey: POSLockStateKey.key(for: 123))
        scope.defaults.set(true, forKey: POSLockStateKey.key(for: 456))

        // When
        POSRolesPersistence.clearAll(staffStorage: InMemoryStaffStorage(), userDefaults: scope.defaults)

        // Then no site's lock flag reads as locked
        #expect(scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == false)
        #expect(scope.defaults.bool(forKey: POSLockStateKey.key(for: 456)) == false)
    }

    @Test func test_clearAll_leaves_unrelated_user_defaults_keys_untouched() {
        // Given a POS lock flag alongside an unrelated app preference
        let scope = UserDefaultsTestScope()
        scope.defaults.set(true, forKey: POSLockStateKey.key(for: 123))
        scope.defaults.set("keep", forKey: "com.woocommerce.someOtherSetting")

        // When
        POSRolesPersistence.clearAll(staffStorage: InMemoryStaffStorage(), userDefaults: scope.defaults)

        // Then the lock-state prefix scan removes only the POS lock flag
        #expect(scope.defaults.bool(forKey: POSLockStateKey.key(for: 123)) == false)
        #expect(scope.defaults.string(forKey: "com.woocommerce.someOtherSetting") == "keep")
    }
}

private extension POSRolesPersistenceTests {
    func makeStaffMemberWithPIN() -> POSStaffMember {
        POSStaffMember(userID: 1,
                       displayName: "Staff",
                       preset: .cashier,
                       capabilities: ["woocommerce_pos_issue_refunds": true],
                       pin: .init(algorithm: "pbkdf2-sha256", iterations: 1,
                                  salt: "c2FsdA==", hash: "aGFzaA=="))
    }
}

@MainActor
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
