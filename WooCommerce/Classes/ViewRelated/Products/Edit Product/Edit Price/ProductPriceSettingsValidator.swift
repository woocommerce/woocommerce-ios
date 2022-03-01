import Foundation

/// Error cases that could occur in product price settings.
///
enum ProductPriceSettingsError: Error {
    case salePriceWithoutRegularPrice
    case salePriceHigherThanRegularPrice
    case newSaleWithEmptySalePrice
}

/// Validation logic for price setting values on products
///
final class ProductPriceSettingsValidator {

    private let currencyFormatter: CurrencyFormatter

    init(currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
    }

    /// Returns the decimal value from a price string.
    ///
    func getDecimalPrice(_ price: String?) -> NSDecimalNumber? {
        guard let price = price else {
            return nil
        }
        return currencyFormatter.convertToDecimal(from: price)
    }

    /// Validates a selection for price settings.
    ///
    func validate(regularPrice: String?, salePrice: String?, dateOnSaleStart: Date?, dateOnSaleEnd: Date?) -> ProductPriceSettingsError? {
        guard doesScheduleDateHasPrice(salePrice: salePrice, dateOnSaleStart: dateOnSaleStart, dateOnSaleEnd: dateOnSaleEnd) else {
            return .newSaleWithEmptySalePrice
        }

        // Check if the sale price is populated, and the regular price is not.
        if getDecimalPrice(salePrice) != nil, getDecimalPrice(regularPrice) == nil {
            return .salePriceWithoutRegularPrice
        }

        // Check if the sale price is less of the regular price, else show an error.
        if let decimalSalePrice = getDecimalPrice(salePrice), let decimalRegularPrice = getDecimalPrice(regularPrice),
           decimalSalePrice.compare(decimalRegularPrice) != .orderedAscending {
            return .salePriceHigherThanRegularPrice
        }

        return nil
    }

    /// Checks if schedule date range is set but sale price is not set.
    ///
    private func doesScheduleDateHasPrice(salePrice: String?, dateOnSaleStart: Date?, dateOnSaleEnd: Date?) -> Bool {
        if dateOnSaleStart != nil && dateOnSaleEnd != nil {
            return getDecimalPrice(salePrice) != nil
        }
        return true
    }
}
