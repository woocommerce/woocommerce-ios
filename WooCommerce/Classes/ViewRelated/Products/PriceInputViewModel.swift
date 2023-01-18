import Foundation
import Yosemite
import WooFoundation

/// View Model logic for the bulk price setting screen
///
final class PriceInputViewModel {

    @Published private(set) var applyButtonEnabled: Bool = false

    @Published private(set) var inputValidationError: ProductPriceSettingsError? = nil

    /// This holds the latest entered price. It is used to perform validations when the user taps the apply button
    /// and for creating a products array with the new price for the bulk update Action
    private(set) var currentPrice: String = ""

    private let productListViewModel: ProductListViewModel

    private let priceSettingsValidator: ProductPriceSettingsValidator
    private let currencySettings: CurrencySettings
    private let currencyFormatter: CurrencyFormatter

    var cancelClosure: () -> Void = {}
    var applyClosure: (String) -> Void = { _ in }

    init(productListViewModel: ProductListViewModel,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.productListViewModel = productListViewModel
        self.priceSettingsValidator = ProductPriceSettingsValidator(currencySettings: currencySettings)
        self.currencySettings = currencySettings
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
    }

    /// Called when the cancel button is tapped
    ///
    func cancelButtonTapped() {
        cancelClosure()
    }

    /// Called when the save button is tapped
    ///
    func applyButtonTapped() {
        inputValidationError = validatePrice()
        guard inputValidationError == nil else {
            return
        }

        applyClosure(currentPrice)
    }

    /// Called when price changes
    ///
    func handlePriceChange(_ price: String?) {
        currentPrice = price ?? ""
        updateButtonStateBasedOnCurrentPrice()
    }

    /// Update the button state to enable/disable based on price value
    ///
    private func updateButtonStateBasedOnCurrentPrice() {
        if currentPrice.isNotEmpty {
            applyButtonEnabled = true
        } else {
            applyButtonEnabled = false
        }
    }

    /// Validates if the currently selected price is valid for all products
    ///
    private func validatePrice() -> ProductPriceSettingsError? {
        for product in productListViewModel.selectedProducts {
            let regularPrice = currentPrice
            let salePrice = product.salePrice

            if let error = priceSettingsValidator.validate(regularPrice: regularPrice,
                                                           salePrice: salePrice,
                                                           dateOnSaleStart: product.dateOnSaleStart,
                                                           dateOnSaleEnd: product.dateOnSaleEnd) {
                return error
            }
        }

        return nil
    }

    /// Returns the footer text to be displayed with information about the current bulk price and how many products will be updated.
    ///
    var footerText: String {
        let numberOfProducts = productListViewModel.selectedProductsCount
        let numberOfProductsText = String.pluralize(numberOfProducts,
                                                      singular: Localization.productsNumberSingularFooter,
                                                      plural: Localization.productsNumberPluralFooter)

        switch productListViewModel.commonPriceForSelectedProducts {
        case .none:
            return [Localization.currentPriceNoneFooter, numberOfProductsText].joined(separator: " ")
        case .mixed:
            return [Localization.currentPriceMixedFooter, numberOfProductsText].joined(separator: " ")
        case let .value(price):
            let currentPriceText = String.localizedStringWithFormat(Localization.currentPriceFooter, formatPriceString(price))
            return [currentPriceText, numberOfProductsText].joined(separator: " ")
        }
    }

    /// It formats a price `String` according to the current price settings.
    ///
    private func formatPriceString(_ price: String) -> String {
        let currencyCode = currencySettings.currencyCode
        let currency = currencySettings.symbol(from: currencyCode)

        return currencyFormatter.formatAmount(price, with: currency) ?? ""
    }

    /// Returns the title to be displayed in the top of bulk update screen
    ///
    func screenTitle() -> String {
        return Localization.screenTitle
    }
}

private extension PriceInputViewModel {
    enum Localization {
        static let screenTitle = NSLocalizedString("Update Regular Price", comment: "Title that appears on top of the of bulk price setting screen")
        static let productsNumberSingularFooter = NSLocalizedString("The price will be updated for %d product.",
                                                                    comment: "Message in the footer of bulk price setting screen (singular).")
        static let productsNumberPluralFooter = NSLocalizedString("The price will be updated for %d products.",
                                                                  comment: "Message in the footer of bulk price setting screen (plurar).")
        static let currentPriceFooter = NSLocalizedString("Current price is %@.",
                                                          comment: "Message in the footer of bulk price setting screen"
                                                          + " with the current price, when it is the same for all products")
        static let currentPriceMixedFooter = NSLocalizedString("Current prices are mixed.",
                                                               comment: "Message in the footer of bulk price setting screen, when products have"
                                                               + " different price values.")
        static let currentPriceNoneFooter = NSLocalizedString("Current price is not set.",
                                                              comment: "Message in the footer of bulk price setting screen, when none of the"
                                                              + " products have price value.")
    }
}
