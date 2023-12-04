import Foundation
import Combine
import SwiftUI
import WooFoundation

final class CashPaymentTenderViewModel: ObservableObject {
    let formattedTotal: String
    let currencyFormatter: CurrencyFormatter

    @Published var tenderButtonIsEnabled: Bool = true
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
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.formattedTotal = formattedTotal
        self.currencyFormatter = .init(currencySettings: storeCurrencySettings)
        customerCash = formattedTotal
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
