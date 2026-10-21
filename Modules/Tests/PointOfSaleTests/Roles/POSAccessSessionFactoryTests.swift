import Testing
import Foundation
import enum Experiments.FeatureFlag
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSAccessSessionFactoryTests {
    @Test func test_make_when_flag_is_off_then_lock_does_not_restrict_access() {
        // Given
        let flags = StubPOSFeatureFlagProviding(enabledFlags: [])

        // When
        let session = POSAccessSessionFactory.make(siteID: 123, featureFlags: flags, fetcher: MockPOSStaffFetcher())
        session.lock()

        // Then
        #expect(session.isLocked == false)
        #expect(session.allows(.issueRefunds))
    }

    @Test func test_make_when_flag_is_on_then_session_can_be_locked() {
        // Given
        let flags = StubPOSFeatureFlagProviding(enabledFlags: [.pointOfSaleRoles])
        let siteID = Int64.min
        let lockKey = POSLockStateKey.key(for: siteID)
        let previousValue = UserDefaults.standard.object(forKey: lockKey)
        defer { UserDefaults.standard.set(previousValue, forKey: lockKey) }

        // When
        let session = POSAccessSessionFactory.make(siteID: siteID, featureFlags: flags, fetcher: MockPOSStaffFetcher())
        session.lock()

        // Then
        #expect(session.isLocked)
    }
}

private final class StubPOSFeatureFlagProviding: POSFeatureFlagProviding {
    let enabledFlags: Set<FeatureFlag>

    init(enabledFlags: Set<FeatureFlag>) {
        self.enabledFlags = enabledFlags
    }

    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool {
        enabledFlags.contains(flag)
    }
}
