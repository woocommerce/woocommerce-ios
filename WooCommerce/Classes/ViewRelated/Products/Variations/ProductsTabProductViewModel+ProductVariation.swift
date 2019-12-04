import UIKit
import Yosemite

extension ProductsTabProductViewModel {
    init(productVariation: ProductVariation, currency: String) {
        imageUrl = productVariation.image?.src
        name = productVariation.attributes.map({ $0.option }).joined(separator: " - ")
        detailsAttributedString = productVariation.createDetailsAttributedString(currency: currency)
    }
}

private extension ProductVariation {
    func createDetailsAttributedString(currency: String) -> NSAttributedString {
        let visibilityText = createVisibilityText()
        let priceText = createPriceText(currency: currency)

        let detailsText = [visibilityText, priceText]
            .compactMap({ $0 })
            .joined(separator: " • ")

        let attributedString = NSMutableAttributedString(string: detailsText,
                                                         attributes: [
                                                            .foregroundColor: UIColor.textSubtle,
                                                            .font: StyleManager.footerLabelFont
            ])
        return attributedString
    }

    func createVisibilityText() -> String? {
        guard purchasable == false else {
            return nil
        }
        return NSLocalizedString("Hidden", comment: "Shown in a Product Variation cell if the variation is not visible (purchasable is false)")
    }

    func createPriceText(currency: String) -> String? {
        let currencyFormatter = CurrencyFormatter()
        return currencyFormatter.formatAmount(price, with: currency)
    }
}
