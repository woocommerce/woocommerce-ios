import Foundation
import Networking
import WooFoundation

public protocol WooPaymentsDepositServiceProtocol {
    func fetchDepositsOverview() async throws -> [WooPaymentsDepositsOverviewByCurrency]
}

public final class WooPaymentsDepositService: WooPaymentsDepositServiceProtocol {
    // MARK: - Properties

    private let wooPaymentsRemote: WCPayRemote
    private var siteID: Int64

    // MARK: - Initialization

    public init(siteID: Int64, credentials: Credentials) {
        self.siteID = siteID
        self.wooPaymentsRemote = WCPayRemote(network: AlamofireNetwork(credentials: credentials))
    }

    // MARK: - Public Methods

    public func fetchDepositsOverview() async throws -> [WooPaymentsDepositsOverviewByCurrency] {
        do {
            let overview = try await wooPaymentsRemote.loadDepositsOverview(for: siteID)
            return depositsOverviewForViews(overview)
        }
    }

    // MARK: - Private Methods

    private func depositsOverviewForViews(_ depositsOverview: Networking.WooPaymentsDepositsOverview) -> [WooPaymentsDepositsOverviewByCurrency] {
        guard let defaultCurrency = CurrencyCode(caseInsensitiveRawValue: depositsOverview.account.defaultCurrency) else {
            DDLogError("💰 Default currency code not recognised \(depositsOverview.account.defaultCurrency)")
            return []
        }

        let currencies = depositsOverview.balance.pending.compactMap { CurrencyCode(caseInsensitiveRawValue: $0.currency) }

        //TODO: check we've not lost any currencies by doing this map, error if we have

        guard currencies.contains(defaultCurrency) else {
            DDLogError("💰 Default currency code not found in balances \(depositsOverview.account.defaultCurrency)")
            return []
        }

        var depositsOverviews: [WooPaymentsDepositsOverviewByCurrency] = []

        for currency in currencies {
            let pendingBalance = depositsOverview.balance.pending.first { CurrencyCode(caseInsensitiveRawValue: $0.currency) == currency }
            let availableBalance = depositsOverview.balance.available.first { CurrencyCode(caseInsensitiveRawValue: $0.currency) == currency }
            let nextDeposit = depositsOverview.deposit.nextScheduled.first { CurrencyCode(caseInsensitiveRawValue: $0.currency) == currency }
            let lastDeposit = depositsOverview.deposit.lastPaid.first { CurrencyCode(caseInsensitiveRawValue: $0.currency) == currency }
            let overview = WooPaymentsDepositsOverviewByCurrency(
                currency: currency,
                automaticDeposits: depositsOverview.account.depositsSchedule.interval != .manual,
                depositInterval: depositsOverview.account.depositsSchedule.interval,
                pendingBalanceAmount: balanceAmount(from: pendingBalance),
                pendingDepositsCount: pendingBalance?.depositsCount ?? 0,
                pendingDepositDays: depositsOverview.account.depositsSchedule.delayDays,
                nextDeposit: nextDepositForView(from: nextDeposit),
                lastDeposit: lastDepositForView(from: lastDeposit),
                availableBalance: balanceAmount(from: availableBalance))
            depositsOverviews.append(overview)
        }

        return depositsOverviews
    }

    private func depositAmountDecimal(from amount: Int,
                                      currency: CurrencyCode,
                                      type: WooPaymentsDepositType = .deposit) -> NSDecimalNumber {
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
        return depositAmountDecimal(from: balance.amount,
                                    currency: currency)
    }

    private func nextDepositForView(from nextDeposit: WooPaymentsDeposit?) -> WooPaymentsDepositsOverviewByCurrency.NextDeposit? {
        guard let nextDeposit,
              let currency = CurrencyCode(caseInsensitiveRawValue: nextDeposit.currency) else {
            return nil
        }
        return WooPaymentsDepositsOverviewByCurrency.NextDeposit(
            amount: depositAmountDecimal(from: nextDeposit.amount,
                                         currency: currency,
                                         type: nextDeposit.type),
            date: nextDeposit.date,
            status: nextDeposit.status)
    }

    private func lastDepositForView(from lastDeposit: WooPaymentsDeposit?) -> WooPaymentsDepositsOverviewByCurrency.LastDeposit? {
        guard let lastDeposit,
              let currency = CurrencyCode(caseInsensitiveRawValue: lastDeposit.currency) else {
            return nil
        }
        return WooPaymentsDepositsOverviewByCurrency.LastDeposit(
            amount: depositAmountDecimal(from: lastDeposit.amount,
                                         currency: currency,
                                         type: lastDeposit.type),
            date: lastDeposit.date)
    }
}
