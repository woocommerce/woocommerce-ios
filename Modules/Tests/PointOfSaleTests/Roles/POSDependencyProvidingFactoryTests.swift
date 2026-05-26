import Testing
import enum Experiments.FeatureFlag
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSDependencyProvidingFactoryTests {
    @Test func test_makeAccessSession_when_flag_is_off_then_returns_unrestricted_session() {
        // Given
        let services = StubPOSDependencyProvider(enabledFlags: [])

        // When
        let session = services.makeAccessSession(siteID: 123)

        // Then
        #expect(session is UnrestrictedPOSAccessSession)
    }

    @Test func test_makeAccessSession_when_flag_is_on_then_returns_default_session() {
        // Given
        let services = StubPOSDependencyProvider(enabledFlags: [.pointOfSaleRoles])

        // When
        let session = services.makeAccessSession(siteID: 123)

        // Then
        #expect(session is DefaultPOSAccessSession)
    }
}

@MainActor
private final class StubPOSDependencyProvider: POSDependencyProviding {
    let featureFlags: POSFeatureFlagProviding

    init(enabledFlags: Set<FeatureFlag>) {
        featureFlags = StubPOSFeatureFlagProviding(enabledFlags: enabledFlags)
    }

    var analytics: POSAnalyticsProviding { fatalError("not used in this test") }
    var currency: POSCurrencySettingsProviding { fatalError("not used in this test") }
    var connectivity: POSConnectivityProviding { fatalError("not used in this test") }
    var externalNavigation: POSExternalNavigationProviding { fatalError("not used in this test") }
    var externalViews: POSExternalViewProviding { fatalError("not used in this test") }
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
