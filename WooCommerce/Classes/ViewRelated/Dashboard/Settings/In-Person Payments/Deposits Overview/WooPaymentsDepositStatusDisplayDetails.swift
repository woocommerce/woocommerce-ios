import SwiftUI
import Yosemite
import WooFoundation

extension WooPaymentsDepositStatus {
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

private extension WooPaymentsDepositStatus {
    enum Localization {
        static let estimated = NSLocalizedString(
            "deposits.currency.overview.depositTable.status.estimated.title",
            value: "Estimated",
            comment: "A status for a deposit, shown in a small badge view")

        static let pending = NSLocalizedString(
            "deposits.currency.overview.depositTable.status.pending.title",
            value: "Pending",
            comment: "A status for a deposit, shown in a small badge view")

        static let inTransit = NSLocalizedString(
            "deposits.currency.overview.depositTable.status.inTransit.title",
            value: "In Transit",
            comment: "A status for a deposit, shown in a small badge view")

        static let paid = NSLocalizedString(
            "deposits.currency.overview.depositTable.status.paid.title",
            value: "Paid",
            comment: "A status for a deposit, shown in a small badge view")

        static let canceled = NSLocalizedString(
            "deposits.currency.overview.depositTable.status.canceled.title",
            value: "Canceled",
            comment: "A status for a deposit, shown in a small badge view")

        static let failed = NSLocalizedString(
            "deposits.currency.overview.depositTable.status.failed.title",
            value: "Failed",
            comment: "A status for a deposit, shown in a small badge view")

        static let unknown = NSLocalizedString(
            "deposits.currency.overview.depositTable.status.unknown.title",
            value: "Unknown",
            comment: "A status for a deposit, shown in a small badge view")
    }
}
