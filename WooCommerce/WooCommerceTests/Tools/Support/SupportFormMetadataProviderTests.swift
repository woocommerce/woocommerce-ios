import Testing
import Yosemite
@testable import WooCommerce

@MainActor
struct SupportFormMetadataProviderTests {

    // MARK: - Pre-fetched System Status Report

    @Test
    func systemFields_when_prefetched_report_provided_then_uses_prefetched_report() {
        // Given
        let sessionManager = SessionManager.makeForTesting(authenticated: true)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let prefetchedReport = "### Pre-fetched System Status Report ###"
        let provider = SupportFormMetadataProvider(
            stores: stores,
            sessionManager: sessionManager,
            systemStatusReport: prefetchedReport
        )

        // When
        let fields = provider.systemFields()

        // Then
        let legacyLogsFieldID: Int64 = 22871957
        #expect(fields[legacyLogsFieldID] == prefetchedReport)
    }
}
