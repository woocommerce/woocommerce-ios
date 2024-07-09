import XCTest
import Yosemite
@testable import WooCommerce

final class GoogleAdsDashboardCardViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 135
    private var stores: MockStoresManager!

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting())
        super.setUp()
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    @MainActor
    func test_canShowOnDashboard_returns_false_when_site_is_ineligible_for_google_ads() async {
        // Given
        let eligibilityChecker = MockGoogleAdsEligibilityChecker(isEligible: false)
        let viewModel = GoogleAdsDashboardCardViewModel(siteID: sampleSiteID, eligibilityChecker: eligibilityChecker)

        // When
        await viewModel.checkAvailability()

        // Then
        XCTAssertFalse(viewModel.canShowOnDashboard)
    }

    @MainActor
    func test_canShowOnDashboard_returns_true_when_site_is_eligible_for_google_ads() async {
        // Given
        let eligibilityChecker = MockGoogleAdsEligibilityChecker(isEligible: true)
        let viewModel = GoogleAdsDashboardCardViewModel(siteID: sampleSiteID, eligibilityChecker: eligibilityChecker)

        // When
        await viewModel.checkAvailability()

        // Then
        XCTAssertTrue(viewModel.canShowOnDashboard)
    }

    @MainActor
    func test_shouldShowErrorState_returns_true_when_fetching_campaigns_fails() async {
        // Given
        let viewModel = GoogleAdsDashboardCardViewModel(siteID: sampleSiteID, stores: stores)
        XCTAssertNil(viewModel.syncingError)
        XCTAssertFalse(viewModel.shouldShowErrorState)

        // When
        let error = NSError(domain: "Test", code: 500)
        mockRequest(lastCampaignResult: .failure(error))
        await viewModel.fetchLastCampaign()

        // Then
        XCTAssertEqual(viewModel.syncingError as? NSError, error)
        XCTAssertTrue(viewModel.shouldShowErrorState)
    }

    @MainActor
    func test_shouldShowShowAllCampaignsButton_returns_true_when_last_campaign_found() async {
        // Given
        let viewModel = GoogleAdsDashboardCardViewModel(siteID: sampleSiteID, stores: stores)
        XCTAssertNil(viewModel.lastCampaign)
        XCTAssertFalse(viewModel.shouldShowShowAllCampaignsButton)

        // When
        let lastCampaign = GoogleAdsCampaign.fake().copy(id: 14325)
        mockRequest(lastCampaignResult: .success([lastCampaign]))
        await viewModel.fetchLastCampaign()

        // Then
        XCTAssertEqual(viewModel.lastCampaign, lastCampaign)
        XCTAssertTrue(viewModel.shouldShowShowAllCampaignsButton)
    }

    @MainActor
    func test_shouldShowCreateCampaignButton_returns_false_when_fetching_campaigns_fails() async {
        // Given
        let viewModel = GoogleAdsDashboardCardViewModel(siteID: sampleSiteID, stores: stores)
        XCTAssertTrue(viewModel.shouldShowCreateCampaignButton)

        // When
        let error = NSError(domain: "Test", code: 500)
        mockRequest(lastCampaignResult: .failure(error))
        await viewModel.fetchLastCampaign()

        // Then
        XCTAssertFalse(viewModel.shouldShowCreateCampaignButton)

        // When
        let lastCampaign = GoogleAdsCampaign.fake().copy(id: 14325)
        mockRequest(lastCampaignResult: .success([lastCampaign]))
        await viewModel.fetchLastCampaign()

        // Then
        XCTAssertTrue(viewModel.shouldShowCreateCampaignButton)
    }

    @MainActor
    func test_syncingData_is_false_immediately_after_fetching_last_campaign_completes( ) async {
        // Given
        let viewModel = GoogleAdsDashboardCardViewModel(siteID: sampleSiteID, stores: stores)

        // When
        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .fetchAdsCampaigns(_, onCompletion):
                XCTAssertTrue(viewModel.syncingData)
                onCompletion(.success([.fake().copy(id: 13453)]))
            case let .retrieveCampaignStats(_, _, _, _, _, onCompletion):
                XCTAssertFalse(viewModel.syncingData)
                onCompletion(.success(.fake()))
            default:
                break
            }
        }
        await viewModel.fetchLastCampaign()

        // Then
        XCTAssertFalse(viewModel.syncingData)

    }

    @MainActor
    func test_lastCampaignStats_is_the_total_when_no_campaign_stats_are_found() async {
        // Given
        let viewModel = GoogleAdsDashboardCardViewModel(siteID: sampleSiteID, stores: stores)
        XCTAssertNil(viewModel.lastCampaignStats)

        // When
        let totals = GoogleAdsCampaignStatsTotals.fake().copy(sales: 0, spend: 0, clicks: 0, impressions: 0)
        let statsResult = GoogleAdsCampaignStats.fake().copy(
            siteID: sampleSiteID,
            totals: totals,
            campaigns: []
        )
        mockRequest(lastCampaignResult: .success([.fake().copy(id: 12423)]),
                    lastCampaignStatsResult: .success(statsResult))
        await viewModel.fetchLastCampaign()

        // Then
        XCTAssertEqual(viewModel.lastCampaignStats, totals)
    }

    @MainActor
    func test_lastCampaignStats_is_correct_when_stats_are_found_for_last_campaign() async {
        // Given
        let viewModel = GoogleAdsDashboardCardViewModel(siteID: sampleSiteID, stores: stores)
        XCTAssertNil(viewModel.lastCampaignStats)

        // When
        let campaign = GoogleAdsCampaign.fake().copy(id: 12423)
        let subtotals = GoogleAdsCampaignStatsTotals.fake().copy(sales: 1, spend: 0, clicks: 2, impressions: 5)
        let statsResult = GoogleAdsCampaignStats.fake().copy(
            siteID: sampleSiteID,
            totals: .fake(),
            campaigns: [.fake().copy(campaignID: campaign.id, subtotals: subtotals)]
        )
        mockRequest(lastCampaignResult: .success([campaign]),
                    lastCampaignStatsResult: .success(statsResult))
        await viewModel.fetchLastCampaign()

        // Then
        XCTAssertEqual(viewModel.lastCampaignStats, subtotals)
    }
}

private extension GoogleAdsDashboardCardViewModelTests {
    func mockRequest(lastCampaignResult: Result<[GoogleAdsCampaign], Error> = .success([]),
                     lastCampaignStatsResult: Result<GoogleAdsCampaignStats, Error> = .success(.fake())) {
        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .fetchAdsCampaigns(_, onCompletion):
                onCompletion(lastCampaignResult)
            case let .retrieveCampaignStats(_, _, _, _, _, onCompletion):
                onCompletion(lastCampaignStatsResult)
            default:
                break
            }
        }
    }
}
