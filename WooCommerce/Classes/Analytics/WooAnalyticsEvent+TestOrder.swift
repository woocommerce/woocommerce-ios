import Foundation

extension WooAnalyticsEvent {
    enum TestOrder {

        /// Tracked when the entry point to test order is displayed on the empty state of order list.
        static func entryPointDisplayed() -> WooAnalyticsEvent {
            .init(statName: .orderListTestOrderDisplayed, properties: [:])
        }

        /// Tracked when the CTA to try test order is tapped on the empty order list screen.
        ///
        static func tryTestOrderTapped() -> WooAnalyticsEvent {
            .init(statName: .orderListTryTestOrderTapped, properties: [:])
        }

        /// Tracked when the CTA to start test order is tapped on the test order screen.
        ///
        static func testOrderStarted() -> WooAnalyticsEvent {
            .init(statName: .testOrderStartTapped, properties: [:])
        }
    }
}
