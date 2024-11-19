import SwiftUI
import Yosemite
import WooFoundation

extension WooPaymentsPayoutStatus {
    var backgroundColor: Color {
        switch self {
        case .estimated:
            return Color(light: Color.withColorStudio(name: .gray, shade: .shade5),
                         dark: Color.withColorStudio(name: .gray, shade: .shade80))
        case .pending:
            return Color(light: Color.withColorStudio(name: .yellow, shade: .shade10),
                         dark: Color.withColorStudio(name: .yellow, shade: .shade70))
        case .inTransit:
            return Color(light: Color.withColorStudio(name: .orange, shade: .shade5),
                         dark: Color.withColorStudio(name: .orange, shade: .shade70))
        case .paid:
            return Color(light: Color.withColorStudio(name: .green, shade: .shade0),
                         dark: Color.withColorStudio(name: .green, shade: .shade50))
        case .canceled:
            return Color(light: Color.withColorStudio(name: .wooCommercePurple, shade: .shade10),
                         dark: Color.withColorStudio(name: .wooCommercePurple, shade: .shade80))
        case .failed:
            return Color(light: Color.withColorStudio(name: .red, shade: .shade5),
                         dark: Color.withColorStudio(name: .red, shade: .shade70))
        case .unknown:
            return Color(light: Color.withColorStudio(name: .gray, shade: .shade5),
                         dark: Color.withColorStudio(name: .gray, shade: .shade80))
        }
    }

    var textColor: Color {
        switch self {
        case .estimated:
            return Color(light: Color.withColorStudio(name: .gray, shade: .shade80),
                         dark: Color.withColorStudio(name: .gray, shade: .shade5))
        case .pending:
            return Color(light: Color.withColorStudio(name: .yellow, shade: .shade70),
                         dark: Color.withColorStudio(name: .yellow, shade: .shade10))
        case .inTransit:
            return Color(light: Color.withColorStudio(name: .orange, shade: .shade70),
                         dark: Color.withColorStudio(name: .orange, shade: .shade5))
        case .paid:
            return Color(light: Color.withColorStudio(name: .green, shade: .shade50),
                         dark: Color.withColorStudio(name: .green, shade: .shade0))
        case .canceled:
            return Color(light: Color.withColorStudio(name: .wooCommercePurple, shade: .shade80),
                         dark: Color.withColorStudio(name: .wooCommercePurple, shade: .shade10))
        case .failed:
            return Color(light: Color.withColorStudio(name: .red, shade: .shade70),
                         dark: Color.withColorStudio(name: .red, shade: .shade5))
        case .unknown:
            return Color(light: Color.withColorStudio(name: .gray, shade: .shade80),
                         dark: Color.withColorStudio(name: .gray, shade: .shade5))
        }
    }

    var localizedName: String {
        switch self {
        case .estimated:
            return Localization.estimated
        case .pending:
            return Localization.pending
        case .inTransit:
            return Localization.inTransit
        case .paid:
            return Localization.paid
        case .canceled:
            return Localization.canceled
        case .failed:
            return Localization.failed
        case .unknown:
            return Localization.unknown
        }
    }
}

private extension WooPaymentsPayoutStatus {
    enum Localization {
        static let estimated = NSLocalizedString(
            "payouts.currency.overview.payoutTable.status.estimated.title",
            value: "Estimated",
            comment: "A status for a payout, shown in a small badge view")

        static let pending = NSLocalizedString(
            "payouts.currency.overview.payoutTable.status.pending.title",
            value: "Pending",
            comment: "A status for a payout, shown in a small badge view")

        static let inTransit = NSLocalizedString(
            "payouts.currency.overview.payoutTable.status.inTransit.title",
            value: "In Transit",
            comment: "A status for a payout, shown in a small badge view")

        static let paid = NSLocalizedString(
            "payouts.currency.overview.payoutTable.status.paid.title",
            value: "Paid",
            comment: "A status for a payout, shown in a small badge view")

        static let canceled = NSLocalizedString(
            "payouts.currency.overview.payoutTable.status.canceled.title",
            value: "Canceled",
            comment: "A status for a payout, shown in a small badge view")

        static let failed = NSLocalizedString(
            "payouts.currency.overview.payoutTable.status.failed.title",
            value: "Failed",
            comment: "A status for a payout, shown in a small badge view")

        static let unknown = NSLocalizedString(
            "payouts.currency.overview.payoutTable.status.unknown.title",
            value: "Unknown",
            comment: "A status for a payout, shown in a small badge view")
    }
}
