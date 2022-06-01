import Foundation
import WooFoundation

/// `UnitInputFormatter` implementation for Coupon Amount input.
///
struct CouponAmountInputFormatter: UnitInputFormatter {
    let priceInputFormatter: PriceInputFormatter

    init(currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         isPercentage: Bool = false) {
        self.priceInputFormatter = PriceInputFormatter(currencySettings: currencySettings)
    }

    func isValid(input: String) -> Bool {
        guard input.isNotEmpty else {
            return false
        }
        return priceInputFormatter.isValid(input: input)
    }

    func format(input text: String?) -> String {
        guard text.isNilOrEmpty else {
            return priceInputFormatter.format(input: text)
        }
        return "0"
    }
}

extension CouponAmountInputFormatter {
    func value(from input: String) -> NSNumber? {
        priceInputFormatter.value(from: input)
    }
}
