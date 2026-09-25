import Foundation
import WooFoundation

struct POSCashSessionMoney {
    private let currencyFormatter: CurrencyFormatter
    private let numberFormatter: NumberFormatter

    init(settings: CurrencySettings) {
        currencyFormatter = CurrencyFormatter(currencySettings: settings)
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.generatesDecimalNumbers = true
        numberFormatter.groupingSeparator = settings.groupingSeparator
        numberFormatter.decimalSeparator = settings.decimalSeparator
        numberFormatter.minimumFractionDigits = settings.fractionDigits
        numberFormatter.maximumFractionDigits = settings.fractionDigits
        self.numberFormatter = numberFormatter
    }

    func format(_ amount: Decimal) -> String {
        currencyFormatter.formatAmount(amount) ?? NSDecimalNumber(decimal: amount).stringValue
    }

    func formatSigned(_ amount: Decimal) -> String {
        let absoluteAmount = amount < 0 ? -amount : amount
        return (amount < 0 ? "−" : "+") + format(absoluteAmount)
    }

    func parse(_ input: String) -> Decimal? {
        numberFormatter.number(from: input.trimmingCharacters(in: .whitespacesAndNewlines))?.decimalValue
    }
}
