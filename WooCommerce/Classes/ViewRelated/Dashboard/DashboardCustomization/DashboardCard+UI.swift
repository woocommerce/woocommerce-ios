import Foundation
import struct Yosemite.DashboardCard

extension DashboardCard {
    var name: String {
        switch type {
        case .onboarding:
            Localization.onboarding
        case .performance:
            Localization.performance
        case .topPerformers:
            Localization.topPerformers
        case .blaze:
            Localization.blazeCampaigns
        }
    }
}

private extension DashboardCard {
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
    }
}
