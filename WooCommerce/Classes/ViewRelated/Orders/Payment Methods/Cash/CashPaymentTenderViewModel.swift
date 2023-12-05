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
    let formattedTotal: String
    let currencyFormatter: CurrencyFormatter
    let onOrderPaid: OrderPaidByCashCallback

    @Published var tenderButtonIsEnabled: Bool = true
    @Published var addNote: Bool = true
    @Published var dueChange: String = ""
    @Published var customerCash: String = "" {
        didSet {
            guard customerCash != oldValue else { return }

            guard let totalAmount = currencyFormatter.convertToDecimal(formattedTotal) as? Decimal,
                  let customerPaidAmount = currencyFormatter.convertToDecimal(customerCash) as? Decimal,
                  customerPaidAmount >= totalAmount else {
                handleInvalidInput()

                return
            }

            handleSufficientPayment(customerPaidAmount: customerPaidAmount, totalAmount: totalAmount)
        }
    }

    init(formattedTotal: String,
         onOrderPaid: @escaping OrderPaidByCashCallback,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.formattedTotal = formattedTotal
        self.onOrderPaid = onOrderPaid
        self.currencyFormatter = .init(currencySettings: storeCurrencySettings)
        customerCash = formattedTotal
    }

    func onTenderButtonTapped() {
        var info: OrderPaidByCashInfo?
        if let customerPaidAmount = currencyFormatter.formatHumanReadableAmount(customerCash) {
            info = .init(customerPaidAmount: customerPaidAmount, changeGivenAmount: dueChange, addNoteWithChangeData: addNote)
        }

        onOrderPaid(info)
    }
}

private extension CashPaymentTenderViewModel {
    func handleInvalidInput() {
        dueChange = "-"
        tenderButtonIsEnabled = false
    }

    func handleSufficientPayment(customerPaidAmount: Decimal, totalAmount: Decimal) {
        tenderButtonIsEnabled = true
        dueChange = currencyFormatter.formatAmount(customerPaidAmount - totalAmount) ?? ""
    }
}
