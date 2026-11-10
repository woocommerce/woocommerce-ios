import Combine
import WooFoundation
import SwiftUI
import Yosemite

final class AddCustomAmountPercentageViewModel: ObservableObject {
    private let currencyFormatter: CurrencyFormatter
    private let baseAmountForPercentage: Decimal

    /// Plain number sent as the fee total. Never send the formatted text: "$1,234.50" parses as 1.234.
    @Published private(set) var amount = "0"
    var percentageCalculatedAmount: String {
        currencyFormatter.formatAmount(amount) ?? ""
    }
    var baseAmountForPercentageString: String {
        guard let formattedAmount = currencyFormatter.formatAmount(baseAmountForPercentage) else {
            return ""
        }

        return formattedAmount
    }

    @Published var percentage = ""

    init(baseAmountForPercentage: Decimal, currencyFormatter: CurrencyFormatter) {
        self.baseAmountForPercentage = baseAmountForPercentage
        self.currencyFormatter = currencyFormatter
    }

    func preset(with fee: OrderFeeLine) {
        guard let totalDecimal = currencyFormatter.convertToDecimal(fee.total) else {
            return
        }

        percentage = currencyFormatter.localize(((totalDecimal as Decimal / baseAmountForPercentage) * 100)) ?? "0"
        amount = fee.total
    }
}

extension AddCustomAmountPercentageViewModel {
    func updatePercentageCalculatedAmount(_ percentage: String) {
        guard percentage.isNotEmpty,
              let decimalInput = currencyFormatter.convertToDecimal(percentage) else {
            amount = "0"
            return
        }
        amount = "\(baseAmountForPercentage * (decimalInput as Decimal) * 0.01)"
    }
}
