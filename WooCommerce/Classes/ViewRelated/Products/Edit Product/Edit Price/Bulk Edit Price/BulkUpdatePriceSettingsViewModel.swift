import Foundation
import Yosemite

/// View Model logic for the bulk price setting screen
///
final class BulkUpdatePriceSettingsViewModel {
    typealias Section = BulkUpdatePriceViewController.Section
    typealias Row = BulkUpdatePriceViewController.Row

    /// Represents the possible states for the save button.
    ///
    enum ButtonState: Equatable {
        case enabled
        case disabled
        case loading
    }

    /// Represents the possible errors during the bulk update
    ///
    enum BulkUpdatePriceError: Error, Equatable {
        case inputValidationError(ProductPriceSettingsError)
        case priceUpdateError
    }

    /// Indicates what price we are editing
    ///
    enum EditingPriceType {
        case regular

        func keyPathForPriceType() -> KeyPath<ProductVariation, String?> {
            switch self {
            case .regular:
                return \.regularPrice
            }
        }
    }

    /// The state of save price setting button
    @Published private(set) var saveButtonState: ButtonState = .disabled

    /// The error state
    @Published private(set) var bulkUpdatePriceError: BulkUpdatePriceError? = nil

    /// A Closure to be called when the price update is successful
    private let priceUpdateDidFinish: () -> Void

    /// This holds the latest entered price. It is used to perform validations when the user taps the save button
    /// and for creating a variations array with the new price for the bulk update Action
    private(set) var currentPrice: String? = nil
    private let siteID: Int64
    private let productID: Int64
    private let bulkUpdateOptionsModel: BulkUpdateOptionsModel
    private let editingPriceType: EditingPriceType
    private let storesManager: StoresManager
    private let priceSettingsValidator: ProductPriceSettingsValidator
    private let currencySettings: CurrencySettings
    private let currencyFormatter: CurrencyFormatter

    init(siteID: Int64,
         productID: Int64,
         bulkUpdateOptionsModel: BulkUpdateOptionsModel,
         editingPriceType: EditingPriceType,
         priceUpdateDidFinish: @escaping () -> Void,
         storesManager: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.siteID = siteID
        self.productID = productID
        self.bulkUpdateOptionsModel = bulkUpdateOptionsModel
        self.priceUpdateDidFinish = priceUpdateDidFinish
        self.editingPriceType = editingPriceType
        self.storesManager = storesManager
        self.priceSettingsValidator = ProductPriceSettingsValidator(currencySettings: currencySettings)
        self.currencySettings = currencySettings
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
    }

    var sections: [Section] {
        return [Section(footer: footerText(), rows: [.price])]
    }

    /// Called when the save button is tapped
    ///
    func saveButtonTapped() {
        bulkUpdatePriceError = validatePrice()
        guard bulkUpdatePriceError == nil else {
            return
        }

        saveButtonState = .loading

        let action = ProductVariationAction.updateProductVariations(siteID: siteID,
                                                                    productID: productID,
                                                                    productVariations: variationsWithUpdatedPrice()) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.priceUpdateDidFinish()
            case let .failure(error):
                DDLogError("⛔️ Error updating product variations: \(error)")
                self.bulkUpdatePriceError = .priceUpdateError
            }

            self.saveButtonState = .enabled
        }

        storesManager.dispatch(action)
    }

    /// Called when price changes
    ///
    func handlePriceChange(_ price: String?) {
        currentPrice = price
        updateButtonStateBasedOnCurrentPrice()
    }

    /// Update the button state to enable/disable based on price value
    ///
    private func updateButtonStateBasedOnCurrentPrice() {
        // While the action button is a loading state do not change the state
        guard saveButtonState != .loading else {
            return
        }
        if let price = currentPrice, price.isNotEmpty {
            saveButtonState = .enabled
        } else {
            saveButtonState = .disabled
        }
    }

    /// Generates a new array of variations that have the new price.
    ///
    private func variationsWithUpdatedPrice() -> [ProductVariation] {
        switch editingPriceType {
        case .regular:
            return bulkUpdateOptionsModel.productVariations.map { $0.copy(regularPrice: currentPrice) }
        }
    }

    /// Validates if the currently selected price is valid for all variations
    ///
    private func validatePrice() -> BulkUpdatePriceError? {

        for variation in bulkUpdateOptionsModel.productVariations {
            let regularPrice = editingPriceType == .regular ? currentPrice : variation.regularPrice
            let salePrice = variation.salePrice

            if let error = priceSettingsValidator.validate(regularPrice: regularPrice,
                                                           salePrice: salePrice,
                                                           dateOnSaleStart: variation.dateOnSaleStart,
                                                           dateOnSaleEnd: variation.dateOnSaleEnd) {
                return .inputValidationError(error)
            }
        }

        return nil
    }

    /// Returns the footer text to be displayed with information about the current bulk price and how many variations will be updated.
    ///
    private func footerText() -> String {
        let numberOfVariations = bulkUpdateOptionsModel.productVariations.count
        let numberOfVariationsText = String.pluralize(numberOfVariations,
                                                      singular: Localization.variationsNumberSingularFooter,
                                                      plural: Localization.variationsNumberPlurarFooter)

        switch bulkUpdateOptionsModel.bulkValueOf(editingPriceType.keyPathForPriceType()) {
        case .none:
            return [Localization.currentPriceNoneFooter, numberOfVariationsText].joined(separator: " ")
        case .mixed:
            return [Localization.currentPriceMixedFooter, numberOfVariationsText].joined(separator: " ")
        case let .value(price):
            let currentPriceText = String.localizedStringWithFormat(Localization.currentPriceFooter, formatPriceString(price))
            return [currentPriceText, numberOfVariationsText].joined(separator: " ")
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

private extension BulkUpdatePriceSettingsViewModel {
    enum Localization {
        static let screenTitle = NSLocalizedString("Update Regular Price", comment: "Title that appears on top of the of bulk price setting screen")
        static let variationsNumberSingularFooter = NSLocalizedString("The price will be updated for %d variation.",
                                                                       comment: "Message in the footer of bulk price setting screen (singular).")
        static let variationsNumberPlurarFooter = NSLocalizedString("The price will be updated for %d variations.",
                                                                     comment: "Message in the footer of bulk price setting screen (plurar).")
        static let currentPriceFooter = NSLocalizedString("Current price is %@.",
                                                          comment: "Message in the footer of bulk price setting screen"
                                                             + " with the current price, when it is the same for all variations")
        static let currentPriceMixedFooter = NSLocalizedString("Current prices are mixed.",
                                                               comment: "Message in the footer of bulk price setting screen, when variations have"
                                                                  + " different price values.")
        static let currentPriceNoneFooter = NSLocalizedString("Current price is not set.",
                                                              comment: "Message in the footer of bulk price setting screen, when none of the"
                                                                 + " variations have price value.")
    }
}
