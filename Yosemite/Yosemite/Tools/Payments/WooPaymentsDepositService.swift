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

    public convenience init?(siteID: Int64, credentials: Credentials?) {
        guard let credentials else {
            DDLogError("⛔️ Could not create deposits service due to not finding credentials")
            return nil
        }
        self.init(siteID: siteID, network: AlamofireNetwork(credentials: credentials))
    }

    public init(siteID: Int64, network: Network) {
        self.siteID = siteID
        self.wooPaymentsRemote = WCPayRemote(network: network)
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
            let lastDeposit = depositsOverview.deposit.lastPaid.first { CurrencyCode(caseInsensitiveRawValue: $0.currency) == currency }
            let overview = WooPaymentsDepositsOverviewByCurrency(
                currency: currency,
                automaticDeposits: depositsOverview.account.depositsSchedule.interval != .manual,
                depositInterval: depositsOverview.account.depositsSchedule.interval,
                pendingBalanceAmount: balanceAmount(from: pendingBalance),
                pendingDepositDays: depositsOverview.account.depositsSchedule.delayDays,
                lastDeposit: lastDepositForView(from: lastDeposit),
                availableBalance: balanceAmount(from: availableBalance))
            depositsOverviews.append(overview)
        }

        moveCurrencyToFront(currency: defaultCurrency, of: &depositsOverviews)

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

    private func lastDepositForView(from lastDeposit: WooPaymentsDeposit?) -> WooPaymentsDepositsOverviewByCurrency.LastDeposit? {
        guard let lastDeposit,
              let currency = CurrencyCode(caseInsensitiveRawValue: lastDeposit.currency) else {
            return nil
        }
        return WooPaymentsDepositsOverviewByCurrency.LastDeposit(
            amount: depositAmountDecimal(from: lastDeposit.amount,
                                         currency: currency,
                                         type: lastDeposit.type),
            date: lastDeposit.date,
            status: lastDeposit.status)
    }

    private func moveCurrencyToFront(currency: CurrencyCode, of depositOverviews: inout [WooPaymentsDepositsOverviewByCurrency]) {
        guard depositOverviews.count > 1,
            let currencyOverviewIndex = depositOverviews.firstIndex(where: { $0.currency == currency }) else {
            return
        }

        let currencyOverview = depositOverviews.remove(at: currencyOverviewIndex)
        depositOverviews.insert(currencyOverview, at: 0)
    }
}
