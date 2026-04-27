import Foundation
import Yosemite
import WooFoundation

final class WooPaymentsPayoutsCurrencyOverviewViewModel: ObservableObject {
    private let overview: WooPaymentsPayoutsOverviewByCurrency
    private let analytics: Analytics
    private let currencySettings: CurrencySettings?
    private let locale: Locale

    init(overview: WooPaymentsPayoutsOverviewByCurrency,
         analytics: Analytics = ServiceLocator.analytics,
         siteCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         locale: Locale = Locale.current) {
        self.overview = overview
        self.analytics = analytics
        self.currency = overview.currency
        self.tabTitle = overview.currency.rawValue.uppercased()
        self.locale = locale

        if overview.currency == siteCurrencySettings.currencyCode {
            currencySettings = siteCurrencySettings
        } else {
            currencySettings = nil
        }

        setupProperties()
    }

    private func setupProperties() {
        pendingBalance = formatAmount(overview.pendingBalanceAmount)
        lastPayoutAmount = formatAmount(overview.lastPayout?.amount ?? NSDecimalNumber(value: 0))
        lastPayoutDate = formatDate(overview.lastPayout?.date) ?? Localization.noDateString
        lastPayoutStatus = overview.lastPayout?.status ?? .unknown
        availableBalance = formatAmount(overview.availableBalance)
        payoutScheduleHint = payoutScheduleHintText()
        balanceTypeHint = balanceTypeHintText()
    }

    @Published var pendingBalance: String = ""
    @Published var lastPayoutAmount: String = ""
    @Published var lastPayoutDate: String = ""
    @Published var lastPayoutStatus: WooPaymentsPayoutStatus = .unknown
    @Published var availableBalance: String = ""
    @Published var payoutScheduleHint: String = ""
    @Published var balanceTypeHint: String = ""
    @Published var showWebviewURL: URL? = nil
    @Published var currency: CurrencyCode
    @Published var tabTitle: String

    private func formatAmount(_ amount: NSDecimalNumber) -> String {
        if let wooCurrencyFormatter {
            return wooCurrencyFormatter.formatAmount(amount) ?? ""
        } else {
            return systemCurrencyFormatter.string(from: amount) ?? ""
        }
    }

    private func payoutScheduleHintText() -> String {
        if overview.automaticPayouts {
            return String(format: Localization.payoutScheduleHintAutomatic,
                          overview.payoutInterval.frequencyDescriptionEvery)
        } else {
            return Localization.payoutScheduleHintManual
        }
    }

    private func balanceTypeHintText() -> String {
        String(format: Localization.balanceTypeHint, overview.pendingPayoutDays)
    }

    private func formatDate(_ date: Date?) -> String? {
        guard let date else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }

    private lazy var wooCurrencyFormatter: CurrencyFormatter? = {
        guard let currencySettings else {
            return nil
        }
        return CurrencyFormatter(currencySettings: currencySettings)
    }()

    private lazy var systemCurrencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = overview.currency.rawValue
        return formatter
    }()

    func expandTapped(expanded: Bool) {
        if expanded {
            analytics.track(.paymentsMenuPayoutSummaryExpanded)
        }
    }

    func learnMoreTapped() {
        showWebviewURL = WooConstants.URLs.wooPaymentsPayoutSchedule.asURL()
        analytics.track(.paymentsMenuPayoutSummaryLearnMoreTapped)
    }
}

private extension WooPaymentsPayoutInterval {
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
            comment: "Shown in a sentence like 'Available funds are paid out automatically, every day'")
        static let weeklyFrequency = NSLocalizedString(
            "every %1$@",
            comment: "every {dayname}, shown in a sentence like 'Available funds are paid out automatically, every Wednesday' " +
            "%1$@ will be replaced with the localized day name")
        static let monthlyFrequencyWithDate = NSLocalizedString(
            "every month on the %1$@",
            comment: "Shown in a sentence like 'Available funds are paid out automatically, every month on the 15th'")
        static let fallbackMonthlyFrequency = NSLocalizedString(
            "every month",
            comment: "Shown in a sentence like 'Available funds are paid out automatically every month.")
        static let manualFrequency = NSLocalizedString(
            "manually, on request",
            comment: "on request (lower case), shown in a sentence like 'Payout schedule: manual, on request'")
    }
}

private extension WooPaymentsPayoutsCurrencyOverviewViewModel {
    enum Localization {
        static let balanceTypeHint = NSLocalizedString(
            "Funds become available after pending for %1$d days.",
            comment: "Hint regarding available/pending balances shown in the WooPayments Payouts View" +
            "%1$d will be replaced by the number of days balances pend, and will be one of 2/4/5/7.")
        static let payoutScheduleHintAutomatic = NSLocalizedString(
            "Available funds are paid out automatically, %1$@.",
            comment: "Hint showing the payout schedule for a merchant's WooPayments account. " +
            "e.g. Available funds are paid out automatically, every Wednesday. " +
            "%1$@ will be replaced with a translated frequency description, e.g. 'every day' or 'monthly on the 28th'")
        static let payoutScheduleHintManual = NSLocalizedString(
            "Available funds are paid out manually, on request.",
            comment: "Hint showing the payout schedule for a merchant's WooPayments account with a manual schedule.")
        static let noDateString = NSLocalizedString(
            "N/A",
            comment: "String used when there's no date available for a payout type on the WooPayments Payouts View.")
        static let estimatedDateString = NSLocalizedString(
            "Est. %1$@",
            comment: "String indicating that a payout date is an estimate. Shown on whe WooPayments Payouts View. " +
            "%1$@ will be replaced with a locale-appropriate date string.")
    }
}
