import Combine
import WooFoundation
import SwiftUI
import Yosemite

final class AddCustomAmountPercentageViewModel: ObservableObject {
    private let currencyFormatter: CurrencyFormatter
    private let baseAmountForPercentage: Decimal

    @Published private(set) var percentageCalculatedAmount: String = ""
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
        percentageCalculatedAmount = "0"
    }

    func preset(with fee: OrderFeeLine) {
        guard let totalDecimal = currencyFormatter.convertToDecimal(fee.total) else {
            return
        }

        percentage = currencyFormatter.localize(((totalDecimal as Decimal / baseAmountForPercentage) * 100)) ?? "0"
        percentageCalculatedAmount = fee.total
    }
}

extension AddCustomAmountPercentageViewModel {
    func updatePercentageCalculatedAmount(_ percentage: String) {
        guard percentage.isNotEmpty,
              let decimalInput = currencyFormatter.convertToDecimal(percentage) else {
            percentageCalculatedAmount = "0"
            return
        }
        let amountString = "\(baseAmountForPercentage * (decimalInput as Decimal) * 0.01)"
        percentageCalculatedAmount = currencyFormatter.formatAmount(amountString) ?? ""
    }
}
