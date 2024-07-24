import XCTest
import WooFoundation
import Yosemite
@testable import WooCommerce

final class GoogleAdsCampaignReportCardViewModelTests: XCTestCase {

    private var eventEmitter: StoreStatsUsageTracksEventEmitter!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!
    private var stores: MockStoresManager!

    private let sampleSiteID: Int64 = 12345
    private let sampleAdminURL = "https://example.com/wp-admin/"

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        eventEmitter = StoreStatsUsageTracksEventEmitter(analytics: analytics)
        stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: .fake().copy(adminURL: sampleAdminURL)))
        ServiceLocator.setCurrencySettings(CurrencySettings()) // Default is US
    }

    func test_isEligibleForGoogleAds_true_when_eligible_for_GoogleAds() async {
        // Given
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .today,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      googleAdsEligibilityChecker: MockGoogleAdsEligibilityChecker(isEligible: true))

        // When
        await vm.reload()

        // Then
        XCTAssertTrue(vm.isEligibleForGoogleAds)
    }

    func test_isEligibleForGoogleAds_false_when_not_eligible_for_GoogleAds() async {
        // Given
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .today,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      googleAdsEligibilityChecker: MockGoogleAdsEligibilityChecker(isEligible: false))

        // When
        await vm.reload()

        // Then
        XCTAssertFalse(vm.isEligibleForGoogleAds)
    }

    func test_GoogleAdsCampaignReportCardViewModel_sets_expected_values_from_campaign_data() async throws {
        // Given
        let campaignStats = sampleCampaignStats()
        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .retrieveCampaignStats(_, _, _, _, _, onCompletion):
                onCompletion(.success(campaignStats))
            default:
                break
            }
        }
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .today,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      stores: stores,
                                                      googleAdsEligibilityChecker: MockGoogleAdsEligibilityChecker(isEligible: true))

        // When
        await vm.reload()

        // Then
        XCTAssertFalse(vm.isRedacted)
        XCTAssertNotNil(vm.reportViewModel)

        // Check metric stats data
        assertEqual("$12,345", vm.statValue)
        assertEqual("+0%", vm.deltaValue)

        // Check campaigns data
        assertEqual(5, vm.campaignsData.count)
        let firstCampaign = try XCTUnwrap(vm.campaignsData.first)
        assertEqual(campaignStats.campaigns.last?.campaignName, firstCampaign.name)
        assertEqual(true, firstCampaign.details.contains("$200"))
        assertEqual("$1,234.56", firstCampaign.value)
        XCTAssertFalse(vm.showCampaignsError)

    }

    func test_reportViewModel_contains_expected_reportURL_elements() throws {
        // When
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .monthToDate,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      stores: stores,
                                                      googleAdsEligibilityChecker: MockGoogleAdsEligibilityChecker(isEligible: true))
        let reportURL = try XCTUnwrap(vm.reportViewModel?.initialURL)
        let reportURLQueryItems = try XCTUnwrap(URLComponents(url: reportURL, resolvingAgainstBaseURL: false)?.queryItems)

        // Then
        XCTAssertTrue(reportURL.relativeString.contains(sampleAdminURL))
        XCTAssertTrue(reportURLQueryItems.contains(URLQueryItem(name: "path", value: "/google/reports")))
        XCTAssertTrue(reportURLQueryItems.contains(URLQueryItem(name: "period", value: "month")))
    }

    func test_GoogleAdsCampaignReportCardViewModel_shows_error_when_current_stats_are_nil() {
        // Given
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .monthToDate,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      stores: stores,
                                                      googleAdsEligibilityChecker: MockGoogleAdsEligibilityChecker(isEligible: true))

        // Then
        XCTAssertTrue(vm.showCampaignsError)
    }

    func test_GoogleAdsCampaignReportCardViewModel_sets_expected_values_when_syncing_remotely() async throws {
        // Given
        var isRedactedWhileSyncing: Bool = false
        var reportViewModelWhileSyncing: AnalyticsReportLinkViewModel?
        var showingCampaignsErrorWhileSyncing: Bool = false
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .monthToDate,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      stores: stores,
                                                      googleAdsEligibilityChecker: MockGoogleAdsEligibilityChecker(isEligible: true))
        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .retrieveCampaignStats(_, _, _, _, _, onCompletion):
                isRedactedWhileSyncing = vm.isRedacted
                reportViewModelWhileSyncing = vm.reportViewModel
                showingCampaignsErrorWhileSyncing = vm.showCampaignsError
                onCompletion(.success(self.sampleCampaignStats()))
            default:
                break
            }
        }

        // When
        await vm.reload()

        // Then
        XCTAssertTrue(isRedactedWhileSyncing)
        XCTAssertNotNil(reportViewModelWhileSyncing)
        XCTAssertFalse(showingCampaignsErrorWhileSyncing)
    }

    func test_campaignData_includes_top_five_campaigns() async throws {
        // Given
        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .retrieveCampaignStats(_, _, _, _, _, onCompletion):
                onCompletion(.success(self.sampleCampaignStats()))
            default:
                break
            }
        }
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .today,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      stores: stores,
                                                      googleAdsEligibilityChecker: MockGoogleAdsEligibilityChecker(isEligible: true))

        // When
        await vm.reload()

        // Then
        // Only five campaigns are included
        assertEqual(5, vm.campaignsData.count)

        // First campaign has the top sales amount
        let firstCampaign = try XCTUnwrap(vm.campaignsData.first)
        assertEqual("$1,234.56", firstCampaign.value)

        // Campaign with lowest sales amount was dropped
        XCTAssertFalse(vm.campaignsData.contains(where: { $0.value == "$234" }))
    }

    func test_changing_selectedStat_updates_displayed_values() async throws {
        // Given
        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .retrieveCampaignStats(_, _, _, _, _, onCompletion):
                onCompletion(.success(self.sampleCampaignStats()))
            default:
                break
            }
        }
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .today,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      stores: stores,
                                                      googleAdsEligibilityChecker: MockGoogleAdsEligibilityChecker(isEligible: true))

        // When
        await vm.reload()
        vm.selectedStat = .spend

        // Then
        assertEqual("$300", vm.statValue)
        assertEqual("+0%", vm.deltaValue)

        // Check campaigns data
        let firstCampaign = try XCTUnwrap(vm.campaignsData.first)
        assertEqual(true, firstCampaign.details.contains("$1,234.56"))
        assertEqual("$200", firstCampaign.value)
    }

    func test_onDisplayCallToAction_tracks_expected_event() throws {
        // Given
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .today,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      analytics: analytics)

        // When
        vm.onDisplayCallToAction()

        // Then
        assertEqual(["googleads_entry_point_displayed"], analyticsProvider.receivedEvents)
        let sourceProperty = try XCTUnwrap(analyticsProvider.receivedProperties.first?["source"] as? String)
        assertEqual("analytics_hub", sourceProperty)
    }

    func test_showCampaignsCTA_is_false_when_card_is_loading() async {
        // Given
        var showCampaignCTAWhileLoading: Bool?
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .today,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      stores: stores,
                                                      googleAdsEligibilityChecker: MockGoogleAdsEligibilityChecker(isEligible: true))
        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .retrieveCampaignStats(_, _, _, _, _, onCompletion):
                showCampaignCTAWhileLoading = vm.showCampaignCTA
                onCompletion(.success(.fake()))
            default:
                break
            }
        }

        // When
        await vm.reload()

        // Then
        assertEqual(false, showCampaignCTAWhileLoading)
    }

    func test_showCampaignsCTA_is_false_when_card_has_loading_error() async {
        // Given
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .today,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      stores: stores,
                                                      googleAdsEligibilityChecker: MockGoogleAdsEligibilityChecker(isEligible: true))
        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .retrieveCampaignStats(_, _, _, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "", code: 0)))
            default:
                break
            }
        }

        // When
        await vm.reload()

        // Then
        XCTAssertFalse(vm.showCampaignCTA)
    }

    func test_showCampaignsCTA_is_false_when_card_has_campaigns_data() async {
        // Given
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .today,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      stores: stores,
                                                      googleAdsEligibilityChecker: MockGoogleAdsEligibilityChecker(isEligible: true))
        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .retrieveCampaignStats(_, _, _, _, _, onCompletion):
                onCompletion(.success(.fake().copy(campaigns: [.fake()])))
            default:
                break
            }
        }

        // When
        await vm.reload()

        // Then
        XCTAssertFalse(vm.showCampaignCTA)
    }

    func test_showCampaignsCTA_is_false_when_store_is_ineligible_for_Google_Ads() {
        // Given
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .today,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      stores: stores,
                                                      googleAdsEligibilityChecker: MockGoogleAdsEligibilityChecker(isEligible: false))

        // Then
        XCTAssertFalse(vm.showCampaignCTA)
    }

    func test_showCampaignsCTA_is_true_when_eligible_for_Google_Ads_and_no_campaigns_in_stats() async {
        // Given
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .today,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      stores: stores,
                                                      googleAdsEligibilityChecker: MockGoogleAdsEligibilityChecker(isEligible: true))
        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .retrieveCampaignStats(_, _, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            default:
                break
            }
        }

        // When
        await vm.reload()

        // Then
        XCTAssertTrue(vm.showCampaignCTA)
    }

    func test_showCampaignsCTA_is_false_when_campaign_was_successfully_created() async {
        // Given
        let vm = GoogleAdsCampaignReportCardViewModel(siteID: sampleSiteID,
                                                      timeRange: .today,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      stores: stores,
                                                      googleAdsEligibilityChecker: MockGoogleAdsEligibilityChecker(isEligible: true))
        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .retrieveCampaignStats(_, _, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            default:
                break
            }
        }

        // When
        await vm.onGoogleCampaignCreated()

        // Then
        XCTAssertFalse(vm.showCampaignCTA)
    }
}

private extension GoogleAdsCampaignReportCardViewModelTests {
    func sampleCampaignStats() -> GoogleAdsCampaignStats {
        GoogleAdsCampaignStats.fake().copy(totals: .fake().copy(sales: 12345, spend: 300),
                                           campaigns: [.fake().copy(subtotals: .fake().copy(sales: 234)),
                                                       .fake().copy(subtotals: .fake().copy(sales: 345)),
                                                       .fake().copy(subtotals: .fake().copy(sales: 456)),
                                                       .fake().copy(subtotals: .fake().copy(sales: 567)),
                                                       .fake().copy(subtotals: .fake().copy(sales: 678)),
                                                       .fake().copy(campaignName: "Spring Ad Campaign",
                                                                                subtotals: .fake().copy(sales: 1234.56,
                                                                                                        spend: 200))])
    }
}
