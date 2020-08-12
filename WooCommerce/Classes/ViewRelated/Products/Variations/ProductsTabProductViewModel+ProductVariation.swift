import UIKit
import Yosemite

extension ProductsTabProductViewModel {
    init(productVariationModel: EditableProductVariationModel, currencySettings: CurrencySettings = .shared) {
        imageUrl = productVariationModel.productVariation.image?.src
        name = productVariationModel.name
        detailsAttributedString = productVariationModel.createDetailsAttributedString(currencySettings: currencySettings)

        imageService = ServiceLocator.imageService
        isSelected = false
    }
}

private extension EditableProductVariationModel {
    func createDetailsAttributedString(currencySettings: CurrencySettings) -> NSAttributedString {
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
}

extension EditableProductVariationModel {
    enum DetailsLocalization {
        static let disabledText = NSLocalizedString("Disabled", comment: "Shown in a Product Variation cell if the variation is disabled")
        static let noPriceText = NSLocalizedString("No price set",
                                                   comment: "Shown in a Product Variation cell if the variation is enabled but does not have a price")
    }
}
