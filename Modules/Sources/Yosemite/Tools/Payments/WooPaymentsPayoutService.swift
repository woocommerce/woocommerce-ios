import Foundation
import Networking
import WooFoundation

public protocol WooPaymentsPayoutServiceProtocol {
    func fetchPayoutsOverview() async throws -> [WooPaymentsPayoutsOverviewByCurrency]
}

public final class WooPaymentsPayoutService: WooPaymentsPayoutServiceProtocol {
    // MARK: - Properties

    private let wooPaymentsRemote: WCPayRemote
    private var siteID: Int64

    // MARK: - Initialization

    public convenience init?(siteID: Int64, credentials: Credentials?) {
        guard let credentials else {
            DDLogError("⛔️ Could not create payouts service due to not finding credentials")
            return nil
        }
        self.init(siteID: siteID, network: AlamofireNetwork(credentials: credentials))
    }

    public init(siteID: Int64, network: Network) {
        self.siteID = siteID
        self.wooPaymentsRemote = WCPayRemote(network: network)
    }

    // MARK: - Public Methods

    public func fetchPayoutsOverview() async throws -> [WooPaymentsPayoutsOverviewByCurrency] {
        do {
            let overview = try await wooPaymentsRemote.loadPayoutsOverview(for: siteID)
            return payoutsOverviewForViews(overview)
        }
    }

    // MARK: - Private Methods

    private func payoutsOverviewForViews(_ payoutsOverview: Networking.WooPaymentsPayoutsOverview) -> [WooPaymentsPayoutsOverviewByCurrency] {
        guard let defaultCurrency = CurrencyCode(caseInsensitiveRawValue: payoutsOverview.account.defaultCurrency) else {
            DDLogError("💰 Default currency code not recognised \(payoutsOverview.account.defaultCurrency)")
            return []
        }

        let currencies = payoutsOverview.balance.pending.compactMap { CurrencyCode(caseInsensitiveRawValue: $0.currency) }

        //TODO: check we've not lost any currencies by doing this map, error if we have

        guard currencies.contains(defaultCurrency) else {
            DDLogError("💰 Default currency code not found in balances \(payoutsOverview.account.defaultCurrency)")
            return []
        }

        var payoutsOverviews: [WooPaymentsPayoutsOverviewByCurrency] = []

        for currency in currencies {
            let pendingBalance = payoutsOverview.balance.pending.first { CurrencyCode(caseInsensitiveRawValue: $0.currency) == currency }
            let availableBalance = payoutsOverview.balance.available.first { CurrencyCode(caseInsensitiveRawValue: $0.currency) == currency }
            let lastPayout = payoutsOverview.deposit.lastPaid.first { CurrencyCode(caseInsensitiveRawValue: $0.currency) == currency }
            let overview = WooPaymentsPayoutsOverviewByCurrency(
                currency: currency,
                automaticPayouts: payoutsOverview.account.payoutsSchedule.interval != .manual,
                payoutInterval: payoutsOverview.account.payoutsSchedule.interval,
                pendingBalanceAmount: balanceAmount(from: pendingBalance),
                pendingPayoutDays: payoutsOverview.account.payoutsSchedule.delayDays,
                lastPayout: lastPayoutForView(from: lastPayout),
                availableBalance: balanceAmount(from: availableBalance))
            payoutsOverviews.append(overview)
        }

        moveCurrencyToFront(currency: defaultCurrency, of: &payoutsOverviews)

        return payoutsOverviews
    }

    private func payoutAmountDecimal(from amount: Int,
                                      currency: CurrencyCode,
                                     type: WooPaymentsPayoutType = .deposit) -> NSDecimalNumber {
        switch type {
        case .deposit:
            return NSDecimalNumber(value: amount).dividing(by: NSDecimalNumber(value: currency.smallestCurrencyUnitMultiplier))
        case .withdrawal:
            return NSDecimalNumber(value: -amount).dividing(by: NSDecimalNumber(value: currency.smallestCurrencyUnitMultiplier))
        }
    }

    private func balanceAmount(from balance: WooPaymentsBalance?) -> NSDecimalNumber {
        guard let balance,
              let currency = CurrencyCode(caseInsensitiveRawValue: balance.currency) else {
            return .zero
        }
        return payoutAmountDecimal(from: balance.amount,
                                    currency: currency)
    }

    private func lastPayoutForView(from lastPayout: WooPaymentsPayout?) -> WooPaymentsPayoutsOverviewByCurrency.LastPayout? {
        guard let lastPayout,
              let currency = CurrencyCode(caseInsensitiveRawValue: lastPayout.currency) else {
            return nil
        }
        return WooPaymentsPayoutsOverviewByCurrency.LastPayout(
            amount: payoutAmountDecimal(from: lastPayout.amount,
                                         currency: currency,
                                         type: lastPayout.type),
            date: lastPayout.date,
            status: lastPayout.status)
    }

    private func moveCurrencyToFront(currency: CurrencyCode, of payoutOverviews: inout [WooPaymentsPayoutsOverviewByCurrency]) {
        guard payoutOverviews.count > 1,
            let currencyOverviewIndex = payoutOverviews.firstIndex(where: { $0.currency == currency }) else {
            return
        }

        let currencyOverview = payoutOverviews.remove(at: currencyOverviewIndex)
        payoutOverviews.insert(currencyOverview, at: 0)
    }
}
