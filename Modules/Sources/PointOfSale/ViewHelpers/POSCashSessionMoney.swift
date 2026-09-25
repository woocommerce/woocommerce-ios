import Foundation
import WooFoundation

struct POSCashSessionMoney {
    let currencySettings: CurrencySettings
    private let currencyFormatter: CurrencyFormatter
    private let numberFormatter: NumberFormatter
    private let currency: String?
    private let precision: Int?

    init(settings: CurrencySettings, session: POSCashSession? = nil) {
        currency = session?.currency
        precision = session?.currencyPrecision
        currencySettings = CurrencySettings(currencyCode: currency.flatMap { CurrencyCode(rawValue: $0.uppercased()) } ?? settings.currencyCode,
                                             currencyPosition: settings.currencyPosition,
                                             thousandSeparator: settings.groupingSeparator,
                                             decimalSeparator: settings.decimalSeparator,
                                             numberOfDecimals: precision ?? settings.fractionDigits)
        currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.generatesDecimalNumbers = true
        numberFormatter.groupingSeparator = settings.groupingSeparator
        numberFormatter.decimalSeparator = settings.decimalSeparator
        numberFormatter.minimumFractionDigits = precision ?? settings.fractionDigits
        numberFormatter.maximumFractionDigits = precision ?? settings.fractionDigits
        self.numberFormatter = numberFormatter
    }

    func format(_ amount: Decimal) -> String {
        if let currency, CurrencyCode(rawValue: currency.uppercased()) == nil {
            let number = numberFormatter.string(from: NSDecimalNumber(decimal: amount)) ?? NSDecimalNumber(decimal: amount).stringValue
            return number + " " + currency
        }
        return currencyFormatter.formatAmount(amount, with: currency, numberOfDecimals: precision) ?? NSDecimalNumber(decimal: amount).stringValue
    }

    func formatSigned(_ amount: Decimal) -> String {
        let absoluteAmount = amount < 0 ? -amount : amount
        return (amount < 0 ? "−" : "+") + format(absoluteAmount)
    }

    func parse(_ input: String) -> Decimal? {
        numberFormatter.number(from: input.trimmingCharacters(in: .whitespacesAndNewlines))?.decimalValue
    }
}
