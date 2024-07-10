import Foundation
import struct Yosemite.DashboardCard

extension DashboardCard.CardType {
    var name: String {
        switch self {
        case .onboarding:
            Localization.onboarding
        case .performance:
            Localization.performance
        case .topPerformers:
            Localization.topPerformers
        case .blaze:
            Localization.blazeCampaigns
        case .inbox:
            Localization.inbox
        case .stock:
            Localization.stock
        case .reviews:
            Localization.reviews
        case .lastOrders:
            Localization.lastOrders
        case .coupons:
            Localization.coupons
        case .googleAds:
            Localization.googleAds
        }
    }
}

private extension DashboardCard.CardType {
    enum Localization {
        static let onboarding = NSLocalizedString(
            "dashboardCard.name.onboarding",
            value: "Store setup",
            comment: "Name for the Store setup dashboard card in the Customize Dashboard screen"
        )
        static let performance = NSLocalizedString(
            "dashboardCard.name.performance",
            value: "Performance",
            comment: "Name for the Performance dashboard card in the Customize Dashboard screen"
        )
        static let topPerformers = NSLocalizedString(
            "dashboardCard.name.topPerformers",
            value: "Top performers",
            comment: "Name for the Top performers dashboard card in the Customize Dashboard screen"
        )
        static let blazeCampaigns = NSLocalizedString(
            "dashboardCard.name.blazeCampaigns",
            value: "Blaze campaigns",
            comment: "Name for the Blaze dashboard card in the Customize Dashboard screen"
        )
        static let stock = NSLocalizedString(
            "dashboardCard.name.stock",
            value: "Stock",
            comment: "Name for the Stock dashboard card in the Customize Dashboard screen"
        )
        static let inbox = NSLocalizedString(
            "dashboardCard.name.inbox",
            value: "Inbox",
            comment: "Name for the Inbox dashboard card in the Customize Dashboard screen"
        )
        static let reviews = NSLocalizedString(
            "dashboardCard.name.reviews",
            value: "Most recent reviews",
            comment: "Name for the Most recent reviews dashboard card in the Customize Dashboard screen"
        )
        static let lastOrders = NSLocalizedString(
            "dashboardCard.name.lastOrders",
            value: "Most recent orders",
            comment: "Name for the Most recent orders dashboard card in the Customize Dashboard screen"
        )
        static let coupons = NSLocalizedString(
            "dashboardCard.name.coupons",
            value: "Most active coupons",
            comment: "Name for the Most active coupons dashboard card in the Customize Dashboard screen"
        )
        static let googleAds = NSLocalizedString(
            "dashboardCard.name.googleAdsCampaigns",
            value: "Google Ads campaigns",
            comment: "Name for the Google Ads campaigns dashboard card in the Customize Dashboard screen"
        )
    }
}
