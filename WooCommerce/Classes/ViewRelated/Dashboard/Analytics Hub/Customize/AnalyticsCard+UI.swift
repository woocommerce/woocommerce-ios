import Foundation
import Yosemite

extension AnalyticsCard {
    /// Localized name of the analytics card.
    ///
    var name: String {
        switch type {
        case .revenue:
            return Localization.revenue
        case .orders:
            return Localization.orders
        case .products:
            return Localization.products
        case .sessions:
            return Localization.sessions
        }
    }
}

// MARK: - Localization
private extension AnalyticsCard {
    private enum Localization {
        static let revenue = NSLocalizedString("analyticsHub.customize.revenue",
                                               value: "Revenue",
                                               comment: "Name for the Revenue analytics card in the Customize Analytics screen")
        static let orders = NSLocalizedString("analyticsHub.customize.orders",
                                              value: "Orders",
                                              comment: "Name for the Orders analytics card in the Customize Analytics screen")
        static let products = NSLocalizedString("analyticsHub.customize.products",
                                                value: "Products",
                                                comment: "Name for the Products analytics card in the Customize Analytics screen")
        static let sessions = NSLocalizedString("analyticsHub.customize.sessions",
                                                value: "Sessions",
                                                comment: "Name for the Sessions analytics card in the Customize Analytics screen")
    }
}
