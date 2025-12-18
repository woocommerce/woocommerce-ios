import UIKit
import Networking

extension WooAnalyticsEvent {
    enum Products {
        /// Event property keys.
        private enum Key {
            static let horizontalSizeClass = "horizontal_size_class"
            static let productType = "product_type"
        }

        static func productListSelected(horizontalSizeClass: UIUserInterfaceSizeClass) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListSelected,
                              properties: [Key.horizontalSizeClass: horizontalSizeClass.nameForAnalytics])
        }

        static func productListReselected(horizontalSizeClass: UIUserInterfaceSizeClass) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListReselected,
                              properties: [Key.horizontalSizeClass: horizontalSizeClass.nameForAnalytics])
        }

        static func productListProductTapped(productType: ProductType,
                                             horizontalSizeClass: UIUserInterfaceSizeClass) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListProductTapped,
                              properties: [
                                Key.productType: productType.rawValue,
                                Key.horizontalSizeClass: horizontalSizeClass.nameForAnalytics
                              ])
        }
    }
}
