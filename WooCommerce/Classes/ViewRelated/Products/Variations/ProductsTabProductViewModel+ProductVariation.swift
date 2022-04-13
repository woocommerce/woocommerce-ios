import UIKit
import Yosemite

extension ProductsTabProductViewModel {
    init(productVariationModel: EditableProductVariationModel,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        imageUrl = productVariationModel.productVariation.image?.src
        name = productVariationModel.name
        detailsAttributedString = productVariationModel.createDetailsAttributedString(currencySettings: currencySettings)
        productVariation = productVariationModel.productVariation
        imageService = ServiceLocator.imageService
        isSelected = false
        isDraggable = false
        detailsString = productVariationModel.createDetailsString(currencySettings: currencySettings)
        skuString = productVariationModel.createSKUString()
    }
}

private extension EditableProductVariationModel {
    func createDetailsAttributedString(currencySettings: CurrencySettings) -> NSAttributedString {
        let stockStatusAttributedString = createStockStatusAttributedString()
        let variationStatusOrPriceAttributedString = createVariationStatusOrPriceAttributedString(currencySettings: currencySettings)

        let detailsAttributedString = NSMutableAttributedString(attributedString: stockStatusAttributedString)
        detailsAttributedString.append(NSAttributedString(string: " • ", attributes: [
            .foregroundColor: UIColor.textSubtle,
            .font: StyleManager.footerLabelFont
        ]))
        detailsAttributedString.append(variationStatusOrPriceAttributedString)
        return NSAttributedString(attributedString: detailsAttributedString)
    }

    func createStockStatusAttributedString() -> NSAttributedString {
        let stockText = createStockText()
        return NSAttributedString(string: stockText,
                                  attributes: [
                                    .foregroundColor: UIColor.textSubtle,
                                    .font: StyleManager.footerLabelFont
        ])
    }

    func createVariationStatusOrPriceAttributedString(currencySettings: CurrencySettings) -> NSAttributedString {
        let currencyCode = currencySettings.currencyCode
        let currency = currencySettings.symbol(from: currencyCode)

        let detailsText: String
        let textColor: UIColor

        if isEnabled == false {
            detailsText = DetailsLocalization.disabledText
            textColor = .textSubtle
        } else if isEnabledAndMissingPrice {
            detailsText = DetailsLocalization.noPriceText
            textColor = .warning
        } else {
            detailsText = createPriceText(currency: currency, currencySettings: currencySettings)
            textColor = .textSubtle
        }

        let attributedString = NSMutableAttributedString(string: detailsText,
                                                         attributes: [
                                                            .foregroundColor: textColor,
                                                            .font: StyleManager.footerLabelFont
        ])
        return attributedString
    }

    func createPriceText(currency: String, currencySettings: CurrencySettings) -> String {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        return currencyFormatter.formatAmount(productVariation.price, with: currency) ?? ""
    }

    func createDetailsString(currencySettings: CurrencySettings) -> String {
        let currencyCode = currencySettings.currencyCode
        let currency = currencySettings.symbol(from: currencyCode)
        let stockText = createStockText()
        let priceText = createPriceText(currency: currency, currencySettings: currencySettings)

        return [stockText, priceText]
            .compactMap({ $0 })
            .joined(separator: " • ")
    }

    func createSKUString() -> String? {
        if let sku = sku, sku.isNotEmpty {
            let format = NSLocalizedString("SKU: %1$@", comment: "SKU number for a product, reads like: SKU: 32425")
            return String.localizedStringWithFormat(format, sku)
        } else {
            return nil
        }
    }
}

extension EditableProductVariationModel {
    enum DetailsLocalization {
        static let disabledText = NSLocalizedString("Disabled", comment: "Shown in a Product Variation cell if the variation is disabled")
        static let noPriceText = NSLocalizedString("No price set",
                                                   comment: "Shown in a Product Variation cell if the variation is enabled but does not have a price")
    }
}
