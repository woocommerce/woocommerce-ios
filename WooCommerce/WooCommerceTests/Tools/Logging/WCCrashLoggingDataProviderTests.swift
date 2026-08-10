import Testing
import WooFoundation
@testable import WooCommerce

struct WCCrashLoggingDataProviderTests {

    @Test func test_sentryDSN_when_build_configuration_is_appStore_then_returns_the_production_DSN() {
        // Given
        let provider = makeProvider(buildConfiguration: .appStore)

        // When
        let dsn = provider.sentryDSN

        // Then
        #expect(dsn == ApiCredentials.sentryDSN)
    }

    @Test func test_sentryDSN_when_build_configuration_is_alpha_then_returns_the_internal_DSN() {
        // Given
        let provider = makeProvider(buildConfiguration: .alpha)

        // When
        let dsn = provider.sentryDSN

        // Then
        #expect(dsn == ApiCredentials.sentryDSNInternal)
    }

    @Test func test_sentryDSN_when_build_configuration_is_localDeveloper_then_returns_the_internal_DSN() {
        // Given
        let provider = makeProvider(buildConfiguration: .localDeveloper)

        // When
        let dsn = provider.sentryDSN

        // Then
        #expect(dsn == ApiCredentials.sentryDSNInternal)
    }
}

private extension WCCrashLoggingDataProviderTests {
    func makeProvider(buildConfiguration: BuildConfiguration) -> WCCrashLoggingDataProvider {
        WCCrashLoggingDataProvider(featureFlagService: MockFeatureFlagService(), buildConfiguration: buildConfiguration)
    }
}
