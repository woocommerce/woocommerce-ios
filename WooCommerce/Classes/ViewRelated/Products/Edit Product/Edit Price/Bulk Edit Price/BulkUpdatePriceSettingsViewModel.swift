import Foundation
import Yosemite

/// View Model logic for the bulk price setting screen
///
final class BulkUpdatePriceSettingsViewModel {
    /// Represents possible states for the save button.
    enum ButtonState: Equatable {
        case enabled
        case disabled
        case loading
    }

    /// Indicates what price we are editting
    ///
    enum EdittingPriceType {
        case regular
        case sale

        func keyPathForPriceType() -> KeyPath<ProductVariation, String?> {
            switch self {
            case .regular:
                return \.regularPrice
            case .sale:
                return \.salePrice
            }
        }
    }

    /// The state of synching all variations
    @Published private(set) var buttonState: ButtonState = .disabled

    /// The error state, true if the product bulk update API call failed. Used to trigger related informational notification
    @Published private(set) var lastUpdateDidFail: Bool = false

    /// The error state, true if the product bulk updat failed
    @Published private(set) var priceValidationError: ProductPriceSettingsError? = nil

    /// A Closure to be called when the price update is successful
    private let priceUpdateDidFinish: () -> Void

    private let productVariations: [ProductVariation]
    private let edittingPriceType: EdittingPriceType
    private let storesManager: StoresManager
    private let priceSettingsValidator: ProductPriceSettingsValidator
    private var currentPrice: String? = nil
    private let siteID: Int64
    private let productID: Int64

    init(siteID: Int64,
         productID: Int64,
         productVariations: [ProductVariation],
         edittingPriceType: EdittingPriceType,
         priceUpdateDidFinish: @escaping () -> Void,
         storesManager: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.siteID = siteID
        self.productID = productID
        self.productVariations = productVariations
        self.priceUpdateDidFinish = priceUpdateDidFinish
        self.edittingPriceType = edittingPriceType
        self.storesManager = storesManager
        self.priceSettingsValidator = ProductPriceSettingsValidator(currencySettings: currencySettings)
    }

    func saveButtonTapped() {
        priceValidationError = validatePrice()
        guard priceValidationError == nil else {
            return
        }

        buttonState = .loading
        lastUpdateDidFail = false

        let action = ProductVariationAction.updateProductVariations(siteID: siteID,
                                                                    productID: productID,
                                                                    productVariations: productVariations) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(_):
                self.lastUpdateDidFail = false
                self.priceUpdateDidFinish()
            case let .failure(error):
                DDLogError("⛔️ Error updating product variations: \(error)")
                self.lastUpdateDidFail = true
            }

            self.updateButtonStateBasedOnCurrentPrice()
        }

        storesManager.dispatch(action)
    }

    func handlePriceChange(_ price: String) {
        currentPrice = price
        updateButtonStateBasedOnCurrentPrice()
    }

    private func updateButtonStateBasedOnCurrentPrice() {
        guard let price = currentPrice, price.isNotEmpty else {
            buttonState = .disabled
            return
        }
        buttonState = .enabled
    }

    private func validatePrice() -> ProductPriceSettingsError? {
        var error: ProductPriceSettingsError?

        for variation in productVariations {
            let regularPrice = edittingPriceType == .regular ? currentPrice : variation.regularPrice
            let salePrice = edittingPriceType == .sale ? currentPrice : variation.salePrice

            error = priceSettingsValidator.validate(regularPrice: regularPrice,
                                                    salePrice: salePrice,
                                                    dateOnSaleStart: variation.dateOnSaleStart,
                                                    dateOnSaleEnd: variation.dateOnSaleEnd)
            if error != nil {
                break
            }
        }

        return error
    }
}
