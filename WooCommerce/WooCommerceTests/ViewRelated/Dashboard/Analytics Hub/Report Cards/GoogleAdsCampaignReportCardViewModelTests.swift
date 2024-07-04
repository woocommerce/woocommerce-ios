import XCTest
import WooFoundation
import Yosemite
@testable import WooCommerce

final class GoogleAdsCampaignReportCardViewModelTests: XCTestCase {

    private var eventEmitter: StoreStatsUsageTracksEventEmitter!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    private let sampleAdminURL = "https://example.com/wp-admin/"

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        eventEmitter = StoreStatsUsageTracksEventEmitter(analytics: analytics)
        ServiceLocator.setCurrencySettings(CurrencySettings()) // Default is US
    }

    func test_GoogleAdsCampaignReportCardViewModel_inits_with_expected_values() throws {
        // Given
        let campaignName = "Spring Ad Campaign"
        let vm = GoogleAdsCampaignReportCardViewModel(
            currentPeriodStats: GoogleAdsCampaignStats.fake().copy(totals: .fake().copy(sales: 12345),
                                                                   campaigns: [.fake().copy(campaignName: campaignName,
                                                                                            subtotals: .init(sales: 1234.56,
                                                                                                             spend: 200,
                                                                                                             clicks: 0,
                                                                                                             impressions: 0,
                                                                                                             conversions: 0)),
                                                                               .fake()]),
            previousPeriodStats: GoogleAdsCampaignStats.fake().copy(totals: .fake().copy(sales: 6172.5)),
            timeRange: .today,
            isRedacted: false,
            usageTracksEventEmitter: eventEmitter,
            storeAdminURL: sampleAdminURL
        )

        // Then
        XCTAssertFalse(vm.isRedacted)
        XCTAssertNotNil(vm.reportViewModel)

        // Check metric stats data
        assertEqual("$12,345", vm.totalSales)
        assertEqual(DeltaPercentage(string: "+100%", direction: .positive), vm.delta)

        // Check campaigns data
        assertEqual(2, vm.campaignsData.count)
        let firstCampaign = try XCTUnwrap(vm.campaignsData.first)
        assertEqual(campaignName, firstCampaign.name)
        assertEqual(true, firstCampaign.details.contains("$200"))
        assertEqual("$1,234.56", firstCampaign.value)
        XCTAssertFalse(vm.showCampaignsError)

    }

    func test_GoogleAdsCampaignReportCardViewModel_contains_expected_reportURL_elements() throws {
        // When
        let vm = GoogleAdsCampaignReportCardViewModel(currentPeriodStats: nil,
                                                      previousPeriodStats: nil,
                                                      timeRange: .monthToDate,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      storeAdminURL: sampleAdminURL)
        let productsCardReportURL = try XCTUnwrap(vm.reportViewModel?.initialURL)
        let productsCardURLQueryItems = try XCTUnwrap(URLComponents(url: productsCardReportURL, resolvingAgainstBaseURL: false)?.queryItems)

        // Then
        XCTAssertTrue(productsCardReportURL.relativeString.contains(sampleAdminURL))
        XCTAssertTrue(productsCardURLQueryItems.contains(URLQueryItem(name: "path", value: "/google/reports")))
        XCTAssertTrue(productsCardURLQueryItems.contains(URLQueryItem(name: "period", value: "month")))
    }

    func test_GoogleAdsCampaignReportCardViewModel_shows_error_when_current_stats_are_nil() {
        // Given
        let vm = GoogleAdsCampaignReportCardViewModel(currentPeriodStats: nil,
                                                      previousPeriodStats: .fake(),
                                                      timeRange: .monthToDate,
                                                      usageTracksEventEmitter: eventEmitter)

        // Then
        XCTAssertTrue(vm.showCampaignsError)
    }

    func test_GoogleAdsCampaignReportCardViewModel_provides_expected_values_when_redacted() throws {
        // Given
        let vm = GoogleAdsCampaignReportCardViewModel(currentPeriodStats: nil,
                                                      previousPeriodStats: nil,
                                                      timeRange: .monthToDate,
                                                      isRedacted: true,
                                                      usageTracksEventEmitter: eventEmitter,
                                                      storeAdminURL: sampleAdminURL)

        // Then
        XCTAssertTrue(vm.isRedacted)
        XCTAssertNotNil(vm.reportViewModel)

        assertEqual("1000", vm.totalSales)
        assertEqual(DeltaPercentage(string: "0%", direction: .zero), vm.delta)

        // Then
        let expectedPlaceholder = TopPerformersRow.Data(showImage: false, name: "Campaign", details: "Spend: $100", value: "$500")
        let firstCampaign = try XCTUnwrap(vm.campaignsData.first)
        assertEqual(expectedPlaceholder.showImage, firstCampaign.showImage)
        assertEqual(expectedPlaceholder.name, firstCampaign.name)
        assertEqual(expectedPlaceholder.details, firstCampaign.details)
        assertEqual(expectedPlaceholder.value, firstCampaign.value)
        XCTAssertFalse(vm.showCampaignsError)
    }

    func test_campaignData_includes_top_five_campaigns() throws {
        // Given
        let vm = GoogleAdsCampaignReportCardViewModel(
            currentPeriodStats: GoogleAdsCampaignStats.fake().copy(campaigns: [.fake().copy(subtotals: .fake().copy(sales: 123)),
                                                                               .fake().copy(subtotals: .fake().copy(sales: 234)),
                                                                               .fake().copy(subtotals: .fake().copy(sales: 345)),
                                                                               .fake().copy(subtotals: .fake().copy(sales: 456)),
                                                                               .fake().copy(subtotals: .fake().copy(sales: 567)),
                                                                               .fake().copy(subtotals: .fake().copy(sales: 678))]),
            previousPeriodStats: nil,
            timeRange: .today,
            usageTracksEventEmitter: eventEmitter)

        // Then
        // Only five campaigns are included
        assertEqual(5, vm.campaignsData.count)

        // First campaign has the top sales amount
        let firstCampaign = try XCTUnwrap(vm.campaignsData.first)
        assertEqual("$678", firstCampaign.value)

        // Campaign with lowest sales amount was dropped
        XCTAssertFalse(vm.campaignsData.contains(where: { $0.value == "$123" }))
    }

}
