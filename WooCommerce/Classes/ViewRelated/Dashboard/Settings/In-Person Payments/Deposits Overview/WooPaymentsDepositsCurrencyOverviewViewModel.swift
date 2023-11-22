import Foundation
import Yosemite

class WooPaymentsDepositsCurrencyOverviewViewModel: ObservableObject {
    let overview: WooPaymentsDepositsOverviewByCurrency
    private let analytics: Analytics

    init(overview: WooPaymentsDepositsOverviewByCurrency,
         analytics: Analytics = ServiceLocator.analytics) {
        self.overview = overview
        self.analytics = analytics
        setupProperties()
    }

    private func setupProperties() {
        pendingBalance = formatAmount(overview.pendingBalanceAmount)
        nextDepositAmount = formatAmount(overview.nextDeposit?.amount ?? NSDecimalNumber(value: 0))
        lastDepositAmount = formatAmount(overview.lastDeposit?.amount ?? NSDecimalNumber(value: 0))
        nextDepositDate = nextDepositDateText()
        lastDepositDate = formatDate(overview.lastDeposit?.date) ?? Localization.noDateString
        availableBalance = formatAmount(overview.availableBalance)
        depositScheduleHint = depositScheduleHintText()
        balanceTypeHint = balanceTypeHintText()
        pendingFundsDepositsSummary = pendingFundsDepositsSummaryText()
    }

    @Published var pendingBalance: String = ""
    @Published var nextDepositAmount: String = ""
    @Published var lastDepositAmount: String = ""
    @Published var nextDepositDate: String = ""
    @Published var lastDepositDate: String = ""
    @Published var availableBalance: String = ""
    @Published var depositScheduleHint: String = ""
    @Published var balanceTypeHint: String = ""
    @Published var pendingFundsDepositsSummary: String = ""

    private func formatAmount(_ amount: NSDecimalNumber) -> String {
        return numberFormatter.string(from: amount) ?? ""
    }

    private func nextDepositDateText() -> String {
        guard let dateString = formatDate(overview.nextDeposit?.date) else {
            return Localization.noDateString
        }
        return String(format: Localization.estimatedDateString,
                      dateString)
    }

    private func depositScheduleHintText() -> String {
        if overview.automaticDeposits {
            return String(format: Localization.depositScheduleHintAutomatic,
                          overview.depositInterval.frequencyDescriptionEvery)
        } else {
            return Localization.depositScheduleHintManual
        }
    }

    private func balanceTypeHintText() -> String {
        String(format: Localization.balanceTypeHint, overview.pendingDepositDays)
    }

    private func pendingFundsDepositsSummaryText() -> String {
        return String.pluralize(overview.pendingDepositsCount,
                                singular: Localization.singleDeposit,
                                plural: Localization.multipleDeposits)
    }

    private func formatDate(_ date: Date?) -> String? {
        guard let date = date else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }

    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = overview.currency.rawValue
        return formatter
    }()

    func expandTapped(expanded: Bool) {
        if expanded {
            analytics.track(.paymentsMenuDepositSummaryExpanded)
        }
    }

    func learnMoreTapped() {
        analytics.track(.paymentsMenuDepositSummaryLearnMoreTapped)
    }
}

private extension WooPaymentsDepositInterval {
    var frequencyDescriptionEvery: String {
        switch self {
        case .daily:
            return Localization.dailyFrequency
        case .weekly(let weekday):
            return String(format: Localization.weeklyFrequency, weekday.localizedName)
        case .monthly(let dayOfMonth):
            let formatter = NumberFormatter()
            formatter.numberStyle = .ordinal

            guard let dayOfMonthString = formatter.string(from: NSNumber(value: dayOfMonth)) else {
                return Localization.fallbackMonthlyFrequency
            }
            return String(format: Localization.monthlyFrequencyWithDate, dayOfMonthString)
        case .manual:
            return Localization.manualFrequency
        }
    }

    enum Localization {
        static let dailyFrequency = NSLocalizedString(
            "every day",
            comment: "Shown in a sentence like 'Available funds are deposited automatically, every day'")
        static let weeklyFrequency = NSLocalizedString(
            "every %1$@",
            comment: "every {dayname}, shown in a sentence like 'Available funds are deposited automatically, every Wednesday' " +
            "%1$@ will be replaced with the localized day name")
        static let monthlyFrequencyWithDate = NSLocalizedString(
            "every month on the %1$@",
            comment: "Shown in a sentence like 'Available funds are deposited automatically, every month on the 15th'")
        static let fallbackMonthlyFrequency = NSLocalizedString(
            "every month",
            comment: "Shown in a sentence like 'Available funds are deposited automatically every month.")
        static let manualFrequency = NSLocalizedString(
            "manually, on request",
            comment: "on request (lower case), shown in a sentence like 'Deposit schedule: manual, on request'")
    }
}

private extension WooPaymentsDepositsCurrencyOverviewViewModel {
    enum Localization {
        static let singleDeposit = NSLocalizedString(
            "%1$d deposit",
            comment: "Singular summary string for the number of pending deposits shown in the WooPayments Deposits " +
            "View. %1$d will be replaced by the number of deposits.")
        static let multipleDeposits = NSLocalizedString(
            "%1$d deposits",
            comment: "Plural summary string for the number of pending deposits shown in the WooPayments Deposits " +
            "View. %1$d will be replaced by the number of deposits.")
        static let balanceTypeHint = NSLocalizedString(
            "Funds become available after pending for %1$d days.",
            comment: "Hint regarding available/pending balances shown in the WooPayments Deposits View" +
            "%1$d will be replaced by the number of days balances pend, and will be one of 2/4/5/7.")
        static let depositScheduleHintAutomatic = NSLocalizedString(
            "Available funds are deposited automatically, %1$@.",
            comment: "Hint showing the deposit schedule for a merchant's WooPayments account. " +
            "e.g. Available funds are deposited automatically, every Wednesday. " +
            "%1$@ will be replaced with a translated frequency description, e.g. 'every day' or 'monthly on the 28th'")
        static let depositScheduleHintManual = NSLocalizedString(
            "Available funds are deposited manually, on request.",
            comment: "Hint showing the deposit schedule for a merchant's WooPayments account with a manual schedule.")
        static let noDateString = NSLocalizedString(
            "N/A",
            comment: "String used when there's no date available for a deposit type on the WooPayments Deposits View.")
        static let estimatedDateString = NSLocalizedString(
            "Est. %1$@",
            comment: "String indicating that a deposit date is an estimate. Shown on whe WooPayments Deposits View. " +
            "%1$@ will be replaced with a locale-appropriate date string.")
    }
}
