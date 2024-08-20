import Foundation
import Combine
import SwiftUI
import WooFoundation

typealias OrderPaidByCashCallback = ((OrderPaidByCashInfo?) -> Void)

struct OrderPaidByCashInfo {
    let customerPaidAmount: String
    let changeGivenAmount: String
    let addNoteWithChangeData: Bool
}

final class CashPaymentTenderViewModel: ObservableObject {
    /// Whether the tender (pay) button is enabled.
    @Published private(set) var tenderButtonIsEnabled: Bool = true
    /// Whether to add an order note about the cash payment details.
    @Published var addNote: Bool = false
    /// The amount of change for the merchant to give back to the customer.
    @Published private(set) var changeDue: String = ""
    /// Whether the change due amount is positive (i.e. whether the merchant needs to give change).
    @Published private(set) var hasChangeDue: Bool = false

    let formattedTotal: String
    let formattableAmountViewModel: FormattableAmountTextFieldViewModel

    /// Keeps track of whether the change due has been calculated (e.g. user has enters a different cash amount from the original amount).
    @Published private var hasCalculatedChangeDue: Bool = false

    private let currencyFormatter: CurrencyFormatter
    private let onOrderPaid: OrderPaidByCashCallback
    private let analytics: Analytics

    init(formattedTotal: String,
         onOrderPaid: @escaping OrderPaidByCashCallback,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics) {
        self.formattedTotal = formattedTotal
        self.formattableAmountViewModel = .init(locale: locale, storeCurrencySettings: storeCurrencySettings)
        self.onOrderPaid = onOrderPaid
        self.analytics = analytics
        self.currencyFormatter = .init(currencySettings: storeCurrencySettings)
        formattableAmountViewModel.presetAmount(formattedTotal)
        observeFormattableAmountForUIStates()
    }

    func onCustomerPaidAmountTapped() {
        formattableAmountViewModel.reset()
    }

    func onMarkOrderAsCompleteButtonTapped() {
        var info: OrderPaidByCashInfo?
        if let customerPaidAmount = currencyFormatter.formatAmount(formattableAmountViewModel.amount) {
            info = .init(customerPaidAmount: customerPaidAmount, changeGivenAmount: changeDue, addNoteWithChangeData: addNote)
        }

        trackOnMarkOrderAsCompleteButtonTapped(with: info)
        onOrderPaid(info)
    }
}

private extension CashPaymentTenderViewModel {
    func observeFormattableAmountForUIStates() {
        // Maps the formatted amount to an optional decimal amount as the change due amount.
        // The value is non-nil when the change due amount is not negative.
        let changeDueAmount: AnyPublisher<Decimal?, Never> = formattableAmountViewModel.$amount.map { [weak self] in
            guard let self else { return nil }
            guard let totalAmount = currencyFormatter.convertToDecimal(formattedTotal) as? Decimal,
                  let customerPaidAmount = currencyFormatter.convertToDecimal($0) as? Decimal,
                  customerPaidAmount >= totalAmount else {
                return nil
            }
            return customerPaidAmount - totalAmount
        }
            .eraseToAnyPublisher()

        changeDueAmount
            .map { [weak self] amount in
                guard let self, let amount, let formattedAmount = currencyFormatter.formatAmount(amount) else {
                    return "-"
                }
                return formattedAmount
            }
            .assign(to: &$changeDue)

        changeDueAmount
            .map { $0 != nil }
            .assign(to: &$tenderButtonIsEnabled)

        changeDueAmount
            .map { amount in
                guard let amount else {
                    return false
                }
                return !amount.isLessThanOrEqualTo(0)
            }
            .assign(to: &$hasChangeDue)

        changeDueAmount
            .scan(false, { hasCalculatedChangeDue, amount in
                guard let amount else {
                    return hasCalculatedChangeDue
                }
                return hasCalculatedChangeDue || !amount.isLessThanOrEqualTo(0)
            })
            .assign(to: &$hasCalculatedChangeDue)
    }

    func trackOnMarkOrderAsCompleteButtonTapped(with info: OrderPaidByCashInfo?) {
        analytics.track(.cashPaymentTenderViewOnMarkOrderAsCompleteButtonTapped, withProperties: [
            "add_note": info?.addNoteWithChangeData ?? false,
            "change_due_was_calculated": hasCalculatedChangeDue
        ])
    }
}
