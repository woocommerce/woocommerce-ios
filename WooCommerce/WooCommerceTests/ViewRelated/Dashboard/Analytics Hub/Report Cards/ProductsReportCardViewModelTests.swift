import XCTest
import WooFoundation
import Yosemite
@testable import WooCommerce

final class ProductsReportCardViewModelTests: XCTestCase {

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

    // MARK: - AnalyticsProductsStatsCardViewModel

    func test_AnalyticsProductsStatsCardViewModel_inits_with_expected_values() {
        // Given
        let vm = AnalyticsProductsStatsCardViewModel(
            currentPeriodStats: OrderStatsV4.fake().copy(totals: .fake().copy(totalItemsSold: 60),
                                                         intervals: [.fake().copy(dateStart: "2024-01-01 00:00:00",
                                                                                  subtotals: .fake().copy(totalItemsSold: 45)),
                                                                     .fake().copy(dateStart: "2024-01-02 00:00:00",
                                                                                  subtotals: .fake().copy(totalItemsSold: 15))]),
            previousPeriodStats: OrderStatsV4.fake().copy(totals: .fake().copy(totalItemsSold: 30)),
            timeRange: .today,
            usageTracksEventEmitter: eventEmitter,
            storeAdminURL: sampleAdminURL
        )

        // Then
        assertEqual("60", vm.itemsSold)
        assertEqual(DeltaPercentage(string: "+100%", direction: .positive), vm.delta)
        XCTAssertFalse(vm.isRedacted)
        XCTAssertFalse(vm.showStatsError)
        XCTAssertNotNil(vm.reportViewModel)
    }

    func test_AnalyticsProductsStatsCardViewModel_contains_expected_reportURL_elements() throws {
        // When
        let vm = AnalyticsProductsStatsCardViewModel(currentPeriodStats: nil,
                                                     previousPeriodStats: nil,
                                                     timeRange: .monthToDate,
                                                     usageTracksEventEmitter: eventEmitter,
                                                     storeAdminURL: sampleAdminURL)
        let productsCardReportURL = try XCTUnwrap(vm.reportViewModel?.initialURL)
        let productsCardURLQueryItems = try XCTUnwrap(URLComponents(url: productsCardReportURL, resolvingAgainstBaseURL: false)?.queryItems)

        // Then
        XCTAssertTrue(productsCardReportURL.relativeString.contains(sampleAdminURL))
        XCTAssertTrue(productsCardURLQueryItems.contains(URLQueryItem(name: "path", value: "/analytics/products")))
        XCTAssertTrue(productsCardURLQueryItems.contains(URLQueryItem(name: "period", value: "month")))
    }

    func test_AnalyticsProductsStatsCardViewModel_shows_sync_error_when_current_stats_are_nil() {
        // Given
        let vm = AnalyticsProductsStatsCardViewModel(currentPeriodStats: nil,
                                                     previousPeriodStats: .fake(),
                                                     timeRange: .monthToDate,
                                                     usageTracksEventEmitter: eventEmitter)

        // Then
        XCTAssertTrue(vm.showStatsError)
    }

    func test_AnalyticsProductsStatsCardViewModel_shows_sync_error_when_previous_stats_are_nil() {
        // Given
        let vm = AnalyticsProductsStatsCardViewModel(currentPeriodStats: .fake(),
                                                     previousPeriodStats: nil,
                                                     timeRange: .monthToDate,
                                                     usageTracksEventEmitter: eventEmitter)

        // Then
        XCTAssertTrue(vm.showStatsError)
    }

    func test_AnalyticsProductsStatsCardViewModel_redact_updates_properties_as_expected() {
        // Given
        let vm = AnalyticsProductsStatsCardViewModel(currentPeriodStats: nil,
                                                     previousPeriodStats: nil,
                                                     timeRange: .monthToDate,
                                                     usageTracksEventEmitter: eventEmitter,
                                                     storeAdminURL: sampleAdminURL)

        // When
        vm.redact()

        // Then

        assertEqual("1000", vm.itemsSold)
        assertEqual(DeltaPercentage(string: "0%", direction: .zero), vm.delta)
        XCTAssertTrue(vm.isRedacted)
        XCTAssertFalse(vm.showStatsError)
        XCTAssertNotNil(vm.reportViewModel)
    }

    func test_AnalyticsProductsStatsCardViewModel_properties_updated_as_expected_after_update() {
        // Given
        let vm = AnalyticsProductsStatsCardViewModel(currentPeriodStats: nil,
                                            previousPeriodStats: nil,
                                            timeRange: .monthToDate,
                                            usageTracksEventEmitter: eventEmitter,
                                            storeAdminURL: sampleAdminURL)

        // When
        vm.update(currentPeriodStats: OrderStatsV4.fake().copy(totals: .fake().copy(totalItemsSold: 60)),
                  previousPeriodStats: OrderStatsV4.fake().copy(totals: .fake().copy(totalItemsSold: 30)))

        // Then
        assertEqual("60", vm.itemsSold)
        assertEqual(DeltaPercentage(string: "+100%", direction: .positive), vm.delta)
        XCTAssertFalse(vm.isRedacted)
    }

    func test_AnalyticsProductsStatsCardViewModel_properties_updated_as_expected_after_timeRange_update() throws {
        // Given
        let vm = AnalyticsProductsStatsCardViewModel(currentPeriodStats: nil,
                                                     previousPeriodStats: nil,
                                                     timeRange: .monthToDate,
                                                     usageTracksEventEmitter: eventEmitter,
                                                     storeAdminURL: sampleAdminURL)

        // When
        vm.update(timeRange: .today)

        // Then
        let reportURL = try XCTUnwrap(vm.reportViewModel?.initialURL)
        let queryItems = try XCTUnwrap(URLComponents(url: reportURL, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "period", value: "today")))
    }

    // MARK: - AnalyticsItemsSoldViewModel

    func test_AnalyticsItemsSoldViewModel_inits_with_expected_values() {
        // Given
        let productName = "Woo!"
        let imageUrl = "https://woo.com/woo.png"
        let vm = AnalyticsItemsSoldViewModel(itemsSoldStats: .fake().copy(items: [
            .fake().copy(productName: productName, quantity: 5, total: 100, currency: "USD", imageUrl: imageUrl)
        ]))

        // Then
        assertEqual(URL(string: imageUrl), vm.itemsSoldData.first?.imageURL)
        assertEqual(productName, vm.itemsSoldData.first?.name)
        assertEqual(true, vm.itemsSoldData.first?.details.contains("$100"))
        assertEqual("5", vm.itemsSoldData.first?.value)
        XCTAssertFalse(vm.isRedacted)
        XCTAssertFalse(vm.showItemsSoldError)
    }

    func test_AnalyticsItemsSoldViewModel_shows_error_when_stats_are_nil() {
        // Given
        let vm = AnalyticsItemsSoldViewModel(itemsSoldStats: nil)

        // Then
        XCTAssertTrue(vm.showItemsSoldError)
    }

    func test_AnalyticsItemsSoldViewModel_redact_updates_properties_as_expected() {
        // Given
        let vm = AnalyticsItemsSoldViewModel(itemsSoldStats: nil)

        // When
        vm.redact()

        // Then
        let expectedPlaceholder = TopPerformersRow.Data(imageURL: nil, name: "Product Name", details: "Net Sales", value: "$5678")
        assertEqual(expectedPlaceholder.imageURL, vm.itemsSoldData.first?.imageURL)
        assertEqual(expectedPlaceholder.name, vm.itemsSoldData.first?.name)
        assertEqual(expectedPlaceholder.details, vm.itemsSoldData.first?.details)
        assertEqual(expectedPlaceholder.value, vm.itemsSoldData.first?.value)
        XCTAssertTrue(vm.isRedacted)
        XCTAssertFalse(vm.showItemsSoldError)
    }

    func test_AnalyticsItemsSoldViewModel_properties_updated_as_expected_after_stats_update() {
        // Given
        let vm = AnalyticsItemsSoldViewModel(itemsSoldStats: nil)

        // When
        let productName = "Woo!"
        vm.update(itemsSoldStats: .fake().copy(items: [
            .fake().copy(productName: productName, quantity: 5, total: 100, currency: "USD", imageUrl: "https://woo.com/woo.png")
        ]))

        // Then
        assertEqual(productName, vm.itemsSoldData.first?.name)
        XCTAssertFalse(vm.isRedacted)
    }

}
