import Testing
@testable import PointOfSale

struct PointOfSaleEntryPointAnalyticsTests {
    @Test(arguments: [
        Selection(eligible: false, hasDatabase: false, hasCoordinator: false, expected: .remote),
        Selection(eligible: false, hasDatabase: false, hasCoordinator: true, expected: .remote),
        Selection(eligible: false, hasDatabase: true, hasCoordinator: false, expected: .remote),
        Selection(eligible: false, hasDatabase: true, hasCoordinator: true, expected: .remote),
        Selection(eligible: true, hasDatabase: false, hasCoordinator: false, expected: .remote),
        Selection(eligible: true, hasDatabase: false, hasCoordinator: true, expected: .remote),
        Selection(eligible: true, hasDatabase: true, hasCoordinator: false, expected: .remote),
        Selection(eligible: true, hasDatabase: true, hasCoordinator: true, expected: .localCatalog)
    ])
    func test_catalog_selection_when_eligibility_and_dependencies_vary_then_matches_actual_source(selection: Selection) {
        // Given the eligibility and dependencies in the test case

        // When
        let strategy = POSCheckoutCatalogStrategy(isLocalCatalogEligible: selection.eligible,
                                                 hasDatabase: selection.hasDatabase,
                                                 hasSyncCoordinator: selection.hasCoordinator)

        // Then
        #expect(strategy == selection.expected)
    }

    struct Selection: Sendable {
        let eligible: Bool
        let hasDatabase: Bool
        let hasCoordinator: Bool
        let expected: POSCheckoutCatalogStrategy
    }
}
