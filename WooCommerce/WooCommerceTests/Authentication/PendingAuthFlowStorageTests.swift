import Foundation
import Testing
@testable import WooCommerce

struct PendingAuthFlowStorageTests {

    private let storageKey = "pendingMagicLinkFlow"

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = UUID().uuidString
        return UserDefaults(suiteName: suiteName)!
    }

    // MARK: - current

    @Test func current_returns_nil_when_nothing_is_stored() {
        // Given
        let userDefaults = makeUserDefaults()
        let storage = PendingAuthFlowStorage(userDefaults: userDefaults)

        // When
        let result = storage.current

        // Then
        #expect(result == nil)
    }

    @Test func current_returns_jetpackSetup_when_stored() {
        // Given
        let userDefaults = makeUserDefaults()
        let storage = PendingAuthFlowStorage(userDefaults: userDefaults)
        storage.updateCurrentFlow(.jetpackSetup)

        // When
        let result = storage.current

        // Then
        #expect(result == .jetpackSetup)
    }

    @Test func current_returns_notificationSetup_when_stored() {
        // Given
        let userDefaults = makeUserDefaults()
        let storage = PendingAuthFlowStorage(userDefaults: userDefaults)
        storage.updateCurrentFlow(.notificationSetup)

        // When
        let result = storage.current

        // Then
        #expect(result == .notificationSetup)
    }

    @Test func current_returns_nil_when_flow_is_expired() {
        // Given
        let userDefaults = makeUserDefaults()
        let storage = PendingAuthFlowStorage(userDefaults: userDefaults)

        // Store an expired flow (16 minutes ago, expiration is 15 minutes)
        let expiredDate = Date().addingTimeInterval(-16 * 60)
        userDefaults.set([PendingAuthFlow.jetpackSetup.rawValue: expiredDate], forKey: storageKey)

        // When
        let result = storage.current

        // Then
        #expect(result == nil)
    }

    @Test func current_returns_flow_when_not_expired() {
        // Given
        let userDefaults = makeUserDefaults()
        let storage = PendingAuthFlowStorage(userDefaults: userDefaults)

        // Store a flow that is not expired (5 minutes ago)
        let recentDate = Date().addingTimeInterval(-5 * 60)
        userDefaults.set([PendingAuthFlow.notificationSetup.rawValue: recentDate], forKey: storageKey)

        // When
        let result = storage.current

        // Then
        #expect(result == .notificationSetup)
    }

    @Test func current_clears_storage_when_expired() {
        // Given
        let userDefaults = makeUserDefaults()
        let storage = PendingAuthFlowStorage(userDefaults: userDefaults)

        // Store an expired flow
        let expiredDate = Date().addingTimeInterval(-16 * 60)
        userDefaults.set([PendingAuthFlow.jetpackSetup.rawValue: expiredDate], forKey: storageKey)

        // When
        _ = storage.current

        // Then
        #expect(userDefaults.dictionary(forKey: storageKey) == nil)
    }

    // MARK: - updateCurrentFlow

    @Test func updateCurrentFlow_stores_flow_with_current_timestamp() {
        // Given
        let userDefaults = makeUserDefaults()
        let storage = PendingAuthFlowStorage(userDefaults: userDefaults)
        let beforeUpdate = Date()

        // When
        storage.updateCurrentFlow(.jetpackSetup)

        // Then
        let afterUpdate = Date()
        let storedDict = userDefaults.dictionary(forKey: storageKey)
        #expect(storedDict != nil)
        #expect(storedDict?.keys.first == PendingAuthFlow.jetpackSetup.rawValue)

        let storedDate = storedDict?[PendingAuthFlow.jetpackSetup.rawValue] as? Date
        #expect(storedDate != nil)
        #expect(storedDate! >= beforeUpdate)
        #expect(storedDate! <= afterUpdate)
    }

    @Test func updateCurrentFlow_overwrites_previous_flow() {
        // Given
        let userDefaults = makeUserDefaults()
        let storage = PendingAuthFlowStorage(userDefaults: userDefaults)
        storage.updateCurrentFlow(.jetpackSetup)

        // When
        storage.updateCurrentFlow(.notificationSetup)

        // Then
        let result = storage.current
        #expect(result == .notificationSetup)
    }

    // MARK: - clear

    @Test func clear_removes_stored_flow() {
        // Given
        let userDefaults = makeUserDefaults()
        let storage = PendingAuthFlowStorage(userDefaults: userDefaults)
        storage.updateCurrentFlow(.jetpackSetup)

        // When
        storage.clear()

        // Then
        #expect(storage.current == nil)
        #expect(userDefaults.dictionary(forKey: storageKey) == nil)
    }

    @Test func clear_succeeds_when_nothing_is_stored() {
        // Given
        let userDefaults = makeUserDefaults()
        let storage = PendingAuthFlowStorage(userDefaults: userDefaults)

        // When/Then - should not throw
        storage.clear()

        #expect(storage.current == nil)
    }
}
