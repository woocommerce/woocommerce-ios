import UIKit

extension WooAnalyticsEvent {
    enum Products {
        /// Event property keys.
        private enum Key {
            static let horizontalSizeClass = "horizontal_size_class"
        }

        static func productListSelected(horizontalSizeClass: UIUserInterfaceSizeClass) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListSelected,
                              properties: [Key.horizontalSizeClass: horizontalSizeClass.nameForAnalytics])
        }

        static func productListReselected(horizontalSizeClass: UIUserInterfaceSizeClass) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListReselected,
                              properties: [Key.horizontalSizeClass: horizontalSizeClass.nameForAnalytics])
        }

        static func productListProductTapped(horizontalSizeClass: UIUserInterfaceSizeClass) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListProductTapped,
                              properties: [Key.horizontalSizeClass: horizontalSizeClass.nameForAnalytics])
        }
    }
}
