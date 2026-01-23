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
                                               comment: "This text appears as a card name in the Customize Analytics screen where users can select which analytics cards to display on their dashboard. It represents one of the available analytics card options that tracks revenue data.")
        static let orders = NSLocalizedString("analyticsHub.customize.orders",
                                              value: "Orders",
                                              comment: "Label for the Orders analytics card in the Customize Analytics screen, where users can select which analytics data to display on their dashboard.")
        static let products = NSLocalizedString("analyticsHub.customize.products",
                                                value: "Products",
                                                comment: "This is the display name for the Products analytics card that appears in the Customize Analytics screen, where users can select which analytics cards to show on their dashboard.")
        static let sessions = NSLocalizedString("analyticsHub.customize.sessions",
                                                value: "Sessions",
                                                comment: "This text appears as the name/label for the Sessions analytics card in the Customize Analytics screen, where users can select which analytics metrics to display on their dashboard.")
        static let bundles = NSLocalizedString("analyticsHub.customize.bundles",
                                                value: "Bundles",
                                                comment: "This text appears as the name/label for the Product Bundles analytics card in the Customize Analytics screen, where users can select which analytics cards to display on their dashboard.")
        static let giftCards = NSLocalizedString("analyticsHub.customize.giftCards",
                                                 value: "Gift Cards",
                                                 comment: "This text appears as the name/label for a Gift Cards analytics card in the Customize Analytics screen, where users can select which analytics metrics to display on their dashboard.")
        static let googleCampaigns = NSLocalizedString("analyticsHub.customize.googleCampaigns",
                                                       value: "Google Campaigns",
                                                       comment: "This text appears as the name/label for a Google Campaigns analytics card in the Customize Analytics screen, where users can select which analytics cards to display on their dashboard.")
    }
}
