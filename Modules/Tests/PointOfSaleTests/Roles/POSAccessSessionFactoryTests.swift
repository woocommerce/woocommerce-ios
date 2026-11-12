import Testing
import enum Experiments.FeatureFlag
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSAccessSessionFactoryTests {
    @Test func test_make_when_flag_is_off_then_returns_unrestricted_session() {
        // Given
        let flags = StubPOSFeatureFlagProviding(enabledFlags: [])

        // When
        let session = POSAccessSessionFactory.make(siteID: 123, featureFlags: flags)

        // Then
        #expect(session is UnrestrictedPOSAccessSession)
    }

    @Test func test_make_when_flag_is_on_then_returns_default_session() {
        // Given
        let flags = StubPOSFeatureFlagProviding(enabledFlags: [.pointOfSaleRoles])

        // When
        let session = POSAccessSessionFactory.make(siteID: 123, featureFlags: flags)

        // Then
        #expect(session is DefaultPOSAccessSession)
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
