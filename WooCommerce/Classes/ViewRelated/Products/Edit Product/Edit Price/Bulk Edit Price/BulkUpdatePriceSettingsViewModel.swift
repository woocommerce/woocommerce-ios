import Foundation
import Yosemite

/// View Model logic for the bulk price setting screen
///
final class BulkUpdatePriceSettingsViewModel {
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
    private var currentPrice: String? = nil
    private let siteID: Int64
    private let productID: Int64
    private let productVariations: [ProductVariation]
    private let editingPriceType: EditingPriceType
    private let storesManager: StoresManager
    private let priceSettingsValidator: ProductPriceSettingsValidator

    init(siteID: Int64,
         productID: Int64,
         productVariations: [ProductVariation],
         editingPriceType: EditingPriceType,
         priceUpdateDidFinish: @escaping () -> Void,
         storesManager: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.siteID = siteID
        self.productID = productID
        self.productVariations = productVariations
        self.priceUpdateDidFinish = priceUpdateDidFinish
        self.editingPriceType = editingPriceType
        self.storesManager = storesManager
        self.priceSettingsValidator = ProductPriceSettingsValidator(currencySettings: currencySettings)
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
        guard let price = currentPrice, price.isNotEmpty else {
            saveButtonState = .disabled
            return
        }
        saveButtonState = .enabled
    }

    /// Generates a new array of variations that have the new price.
    ///
    private func variationsWithUpdatedPrice() -> [ProductVariation] {
        switch editingPriceType {
        case .regular:
            return productVariations.map { $0.copy(regularPrice: currentPrice) }
        }
    }

    /// Validates if the currently selected price is valid for all variations
    ///
    private func validatePrice() -> BulkUpdatePriceError? {

        for variation in productVariations {
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
}
