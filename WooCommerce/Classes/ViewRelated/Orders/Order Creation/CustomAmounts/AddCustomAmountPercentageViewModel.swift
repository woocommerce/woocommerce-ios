import Combine
import WooFoundation
import SwiftUI
import Yosemite

final class AddCustomAmountPercentageViewModel: ObservableObject {
    let currencyFormatter: CurrencyFormatter
    let baseAmountForPercentage: Decimal

    @Published var percentageCalculatedAmount: String = "" {
        didSet {
            guard percentageCalculatedAmount != oldValue else { return }

            percentageCalculatedAmount = currencyFormatter.formatAmount(percentageCalculatedAmount) ?? ""
        }
    }

    var baseAmountForPercentageString: String {
        guard let formattedAmount = currencyFormatter.formatAmount(baseAmountForPercentage) else {
            return ""
        }

        return formattedAmount
    }

    @Published var percentage = "" {
        didSet {
            guard oldValue != percentage else { return }

            updateAmountBasedOnPercentage(percentage)
        }
    }

    init(baseAmountForPercentage: Decimal, currencyFormatter: CurrencyFormatter) {
        self.baseAmountForPercentage = baseAmountForPercentage
        self.currencyFormatter = currencyFormatter
        percentageCalculatedAmount = "0"
    }

    func updateAmountBasedOnPercentage(_ percentage: String) {
        guard percentage.isNotEmpty,
              let decimalInput = currencyFormatter.convertToDecimal(percentage) else {
            percentageCalculatedAmount = "0"
            return
        }

        percentageCalculatedAmount = "\(baseAmountForPercentage * (decimalInput as Decimal) * 0.01)"
    }

    func preset(with fee: OrderFeeLine) {
        guard let totalDecimal = currencyFormatter.convertToDecimal(fee.total) else {
            return
        }

        percentage = currencyFormatter.localize(((totalDecimal as Decimal / baseAmountForPercentage) * 100)) ?? "0"
        percentageCalculatedAmount = fee.total
    }
}
