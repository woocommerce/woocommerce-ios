import Foundation

extension WooAnalyticsEvent {
    enum TestOrder {
        enum Keys {
            static let isWooExpressStore = "is_wooexpress_store"
        }

        /// Tracked when the entry point to test order is displayed on the empty state of order list.
        /// - Parameters:
        ///     - isWooExpressStore: whether the current store is running a WooExpress plan.
        ///
        static func entryPointDisplayed(isWooExpressStore: Bool) -> WooAnalyticsEvent {
            .init(statName: .orderListTestOrderDisplayed, properties: [
                Keys.isWooExpressStore: isWooExpressStore
            ])
        }

        /// Tracked when the CTA to try test order is tapped on the empty order list screen.
        /// - Parameters:
        ///     - isWooExpressStore: whether the current store is running a WooExpress plan.
        ///
        static func tryTestOrderTapped(isWooExpressStore: Bool) -> WooAnalyticsEvent {
            .init(statName: .orderListTryTestOrderTapped, properties: [
                Keys.isWooExpressStore: isWooExpressStore
            ])
        }

        /// Tracked when the CTA to start test order is tapped on the test order screen.
        /// - Parameters:
        ///     - isWooExpressStore: whether the current store is running a WooExpress plan.
        ///
        static func testOrderStarted(isWooExpressStore: Bool) -> WooAnalyticsEvent {
            .init(statName: .testOrderStartTapped, properties: [
                Keys.isWooExpressStore: isWooExpressStore
            ])
        }
    }
}
