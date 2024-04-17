import Foundation
import struct Yosemite.DashboardCard

extension DashboardCard {
    var name: String {
        switch type {
        case .onboarding:
            Localization.onboarding
        case .statsAndTopPerformers:
            Localization.statsAndTopPerformers
        case .blaze:
            Localization.blaze
        }
    }
}

private extension DashboardCard {
    enum Localization {
        static let onboarding = NSLocalizedString(
            "dashboardCard.name.onboarding",
            value: "Store Onboarding",
            comment: "Name for the Store Onboarding dashboard card in the Customize Dashboard screen"
        )
        static let statsAndTopPerformers = NSLocalizedString(
            "dashboardCard.name.statsAndTopPerformers",
            value: "Store Stats and Top Performers",
            comment: "Name for the Store Stats and Top Performers dashboard card in the Customize Dashboard screen"
        )
        static let blaze = NSLocalizedString(
            "dashboardCard.name.blaze",
            value: "Blaze",
            comment: "Name for the Blaze dashboard card in the Customize Dashboard screen"
        )
    }
}
