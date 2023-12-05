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
    private let currencyFormatter: CurrencyFormatter
    private let onOrderPaid: OrderPaidByCashCallback
    private let analytics: Analytics

    var didTapOnCustomerPaidTextField = false
    @Published var tenderButtonIsEnabled: Bool = true
    @Published var addNote: Bool = false
    @Published var changeDue: String = ""
    @Published var customerPaidAmount: String = "" {
        didSet {
            guard customerPaidAmount != oldValue else { return }

            guard let totalAmount = currencyFormatter.convertToDecimal(formattedTotal) as? Decimal,
                  let customerPaidAmount = currencyFormatter.convertToDecimal(customerPaidAmount) as? Decimal,
                  customerPaidAmount >= totalAmount else {
                handleInvalidInput()

                return
            }

            handleSufficientPayment(customerPaidAmount: customerPaidAmount, totalAmount: totalAmount)
        }
    }

    init(formattedTotal: String,
         onOrderPaid: @escaping OrderPaidByCashCallback,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics) {
        self.formattedTotal = formattedTotal
        self.onOrderPaid = onOrderPaid
        self.analytics = analytics
        self.currencyFormatter = .init(currencySettings: storeCurrencySettings)
        customerPaidAmount = formattedTotal
    }

    func onMarkOrderAsCompleteButtonTapped() {
        var info: OrderPaidByCashInfo?
        if let customerPaidAmount = currencyFormatter.formatHumanReadableAmount(customerPaidAmount) {
            info = .init(customerPaidAmount: customerPaidAmount, changeGivenAmount: changeDue, addNoteWithChangeData: addNote)
        }


        trackOnMarkOrderAsCompleteButtonTapped(with: info)
        onOrderPaid(info)
    }
}

private extension CashPaymentTenderViewModel {
    func handleInvalidInput() {
        changeDue = "-"
        tenderButtonIsEnabled = false
    }

    func handleSufficientPayment(customerPaidAmount: Decimal, totalAmount: Decimal) {
        tenderButtonIsEnabled = true
        changeDue = currencyFormatter.formatAmount(customerPaidAmount - totalAmount) ?? ""
    }

    func trackOnMarkOrderAsCompleteButtonTapped(with info: OrderPaidByCashInfo?) {
        analytics.track(.cashPaymentTenderViewOnMarkOrderAsCompleteButtonTapped, withProperties: ["add_note": info?.addNoteWithChangeData ?? false,
                                                                                                  "change_due_was_calculated": didTapOnCustomerPaidTextField])
    }
}
