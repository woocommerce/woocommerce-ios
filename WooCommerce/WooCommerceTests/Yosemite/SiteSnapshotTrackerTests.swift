import XCTest
import Yosemite
@testable import WooCommerce

final class SiteSnapshotTrackerTests: XCTestCase {
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
    }

    // MARK: - `needsTracking`

    func test_needsTracking_is_true_when_the_site_snapshot_has_not_been_tracked() throws {
        // Given
        let tracker = SiteSnapshotTracker(siteID: 7,
                                          analytics: analytics,
                                          userDefaults: userDefaults)

        // The
        XCTAssertTrue(tracker.needsTracking())
    }

    func test_needsTracking_is_false_when_the_site_snapshot_has_been_tracked() throws {
        // Given
        userDefaults.set([7], forKey: .siteIDsWithSnapshotTracked)
        let tracker = SiteSnapshotTracker(siteID: 7,
                                          analytics: analytics,
                                          userDefaults: userDefaults)

        // Then
        XCTAssertFalse(tracker.needsTracking())
    }

    // MARK: - `trackIfNeeded`

    func test_event_is_tracked_when_the_site_snapshot_has_not_been_tracked() throws {
        // Given
        let orderStatuses: [OrderStatus] = [.fake().copy(total: 6), .fake().copy(total: 109)]
        let systemPlugins: [SystemPlugin] = [
            // Paypal plugin is installed but not active.
            .fake().copy(plugin: "woocommerce-paypal-payments/woocommerce-paypal-payments.php",
                         active: false),
            // Plugin with a similar prefix as the WCPay plugin.
            .fake().copy(plugin: "woocommerce-payments-dev-tools-trunk/woocommerce-payments-dev-tools.php",
                         active: false),
            // WCPay plugin is active.
            .fake().copy(plugin: "woocommerce-payments/woocommerce-payments.php", active: true),
            // The other payment plugins are not installed.
        ]
        let tracker = SiteSnapshotTracker(siteID: 7,
                                          analytics: analytics,
                                          userDefaults: userDefaults)

        // When
        tracker.trackIfNeeded(orderStatuses: orderStatuses,
                              numberOfProducts: 98,
                              systemPlugins: systemPlugins)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)
        let event = try XCTUnwrap(analyticsProvider.receivedEvents.first)
        XCTAssertEqual(event, "application_store_snapshot")
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(eventProperties["orders_count"] as? Int64, 115)
        XCTAssertEqual(eventProperties["products_count"] as? Int64, 98)
        XCTAssertEqual(eventProperties["woocommerce_payments"] as? String, "installed_and_activated")
        XCTAssertEqual(eventProperties["woocommerce_gateway_stripe"] as? String, "not_installed")
        XCTAssertEqual(eventProperties["woocommerce_square"] as? String, "not_installed")
        XCTAssertEqual(eventProperties["woocommerce_paypal_payments"] as? String, "installed_and_not_activated")
    }

    func test_event_is_not_tracked_when_the_site_snapshot_has_been_tracked() throws {
        // Given
        userDefaults.set([7], forKey: .siteIDsWithSnapshotTracked)

        let tracker = SiteSnapshotTracker(siteID: 7,
                                          analytics: analytics,
                                          userDefaults: userDefaults)

        // When
        tracker.trackIfNeeded(orderStatuses: [], numberOfProducts: 8, systemPlugins: [])

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 0)
    }

    func test_UserDefaults_siteIDsWithSnapshotTracked_is_updated_with_siteID_when_the_site_snapshot_has_not_been_tracked() throws {
        // Given
        XCTAssertNil(userDefaults[.siteIDsWithSnapshotTracked])

        let tracker = SiteSnapshotTracker(siteID: 7,
                                          analytics: analytics,
                                          userDefaults: userDefaults)

        // When
        tracker.trackIfNeeded(orderStatuses: [], numberOfProducts: 8, systemPlugins: [])

        // Then
        XCTAssertEqual(userDefaults[.siteIDsWithSnapshotTracked], [7])
    }
}
