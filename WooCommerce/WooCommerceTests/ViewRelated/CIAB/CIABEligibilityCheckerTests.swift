import XCTest
@testable import WooCommerce
@testable import Yosemite

class CIABEligibilityCheckerTests: XCTestCase {
    private var sessionManager: SessionManager!
    private var checker: CIABEligibilityChecker!

    override func setUp() {
        super.setUp()
        sessionManager = .makeForTesting()
        checker = CIABEligibilityChecker(
            currentSite: {
                return MockStoresManager(
                    sessionManager: self.sessionManager
                ).sessionManager.defaultSite
            }
        )
    }

    override func tearDown() {
        checker = nil
        sessionManager = nil
        super.tearDown()
    }

    // MARK: - isCurrentSiteCIAB

    func test_is_current_site_ciab_when_no_default_site_returns_false() {
        // Given
        sessionManager.defaultSite = nil

        // Then
        XCTAssertFalse(checker.isCurrentSiteCIAB)
    }

    func test_is_current_site_ciab_when_default_site_is_ciab_returns_true() {
        // Given
        sessionManager.defaultSite = makeCIABSite()

        // Then
        XCTAssertTrue(checker.isCurrentSiteCIAB)
    }

    func test_is_current_site_ciab_when_default_site_is_not_ciab_returns_false() {
        // Given
        sessionManager.defaultSite = makeNonCIABGardenSite()

        // Then
        XCTAssertFalse(checker.isCurrentSiteCIAB)
    }

    func test_is_current_site_ciab_when_default_site_is_non_garden_returns_false() {
        // Given
        sessionManager.defaultSite = makeNonGardenSite()

        // Then
        XCTAssertFalse(checker.isCurrentSiteCIAB)
    }

    // MARK: - isSiteCIAB

    func test_is_site_ciab_with_ciab_site_returns_true() {
        // Given
        let site = makeCIABSite()

        // Then
        XCTAssertTrue(checker.isSiteCIAB(site))
    }

    func test_is_site_ciab_with_non_ciab_garden_site_returns_false() {
        // Given
        let site = makeNonCIABGardenSite()

        // Then
        XCTAssertFalse(checker.isSiteCIAB(site))
    }

    func test_is_site_ciab_with_non_garden_site_returns_false() {
        // Given
        let site = makeNonGardenSite()

        // Then
        XCTAssertFalse(checker.isSiteCIAB(site))
    }

    // MARK: - isFeatureSupportedForCurrentSite

    func test_is_feature_supported_for_current_site_when_not_ciab_returns_true() {
        // Given
        sessionManager.defaultSite = makeNonCIABGardenSite()

        // Then
        XCTAssertTrue(checker.isFeatureSupportedForCurrentSite(.payments))
    }

    func test_is_feature_supported_for_current_site_when_ciab_and_feature_unsupported_returns_false() {
        // Given
        sessionManager.defaultSite = makeCIABSite()

        // Then
        XCTAssertFalse(checker.isFeatureSupportedForCurrentSite(.payments))
    }

    // MARK: - isFeatureSupported(for:)

    func test_is_feature_supported_for_site_when_not_ciab_returns_true() {
        // Given
        let site = makeNonCIABGardenSite()

        // Then
        XCTAssertTrue(checker.isFeatureSupported(.payments, for: site))
    }

    func test_is_feature_supported_for_site_when_ciab_and_feature_unsupported_returns_false() {
        // Given
        let site = makeCIABSite()

        // Then
        XCTAssertFalse(checker.isFeatureSupported(.payments, for: site))
    }

    // MARK: - isCurrentSiteCIABProPlan

    func test_is_current_site_ciab_pro_plan_when_no_default_site_returns_false() {
        // Given
        sessionManager.defaultSite = nil

        // Then
        XCTAssertFalse(checker.isCurrentSiteCIABProPlan)
    }

    func test_is_current_site_ciab_pro_plan_when_non_ciab_site_returns_false() {
        // Given
        sessionManager.defaultSite = makeNonGardenSite()

        // Then
        XCTAssertFalse(checker.isCurrentSiteCIABProPlan)
    }

    func test_is_current_site_ciab_pro_plan_when_ciab_with_pro_monthly_returns_true() {
        // Given
        sessionManager.defaultSite = makeCIABSite(plan: "woo_hosted_pro_plan_monthly")

        // Then
        XCTAssertTrue(checker.isCurrentSiteCIABProPlan)
    }

    func test_is_current_site_ciab_pro_plan_when_ciab_with_pro_yearly_returns_true() {
        // Given
        sessionManager.defaultSite = makeCIABSite(plan: "woo_hosted_pro_plan_yearly")

        // Then
        XCTAssertTrue(checker.isCurrentSiteCIABProPlan)
    }

    func test_is_current_site_ciab_pro_plan_when_ciab_with_free_plan_returns_false() {
        // Given
        sessionManager.defaultSite = makeCIABSite(plan: "woo_hosted_free_plan")

        // Then
        XCTAssertFalse(checker.isCurrentSiteCIABProPlan)
    }

    func test_is_current_site_ciab_pro_plan_when_ciab_with_basic_plan_returns_false() {
        // Given
        sessionManager.defaultSite = makeCIABSite(plan: "woo_hosted_basic_plan_monthly")

        // Then
        XCTAssertFalse(checker.isCurrentSiteCIABProPlan)
    }
}

// MARK: - Helpers
private extension CIABEligibilityCheckerTests {
    func makeCIABSite(plan: String = "") -> Site {
        Site.fake().copy(
            plan: plan,
            isGarden: true,
            gardenName: "commerce"
        )
    }

    func makeNonCIABGardenSite() -> Site {
        Site.fake().copy(
            isGarden: true,
            gardenName: "not-commerce"
        )
    }

    func makeNonGardenSite() -> Site {
        Site.fake().copy(isGarden: false)
    }
}
