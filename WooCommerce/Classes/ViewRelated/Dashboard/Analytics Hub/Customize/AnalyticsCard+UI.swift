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
        case .bundles:
            return Localization.bundles
        case .giftCards:
            return Localization.giftCards
        case .googleCampaigns:
            return Localization.googleCampaigns
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
        static let bundles = NSLocalizedString("analyticsHub.customize.bundles",
                                                value: "Bundles",
                                                comment: "Name for the Product Bundles analytics card in the Customize Analytics screen")
        static let giftCards = NSLocalizedString("analyticsHub.customize.giftCards",
                                                 value: "Gift Cards",
                                                 comment: "Name for the Gift Cards analytics card in the Customize Analytics screen")
        static let googleCampaigns = NSLocalizedString("analyticsHub.customize.googleCampaigns",
                                                       value: "Google Campaigns",
                                                       comment: "Name for the Google Campaigns analytics card in the Customize Analytics screen")
    }
}
