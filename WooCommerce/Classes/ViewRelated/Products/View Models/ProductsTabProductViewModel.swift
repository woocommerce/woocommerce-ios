import Foundation
import Yosemite

private extension ProductStatus {
    var descriptionColor: UIColor {
        switch self {
        case .draft:
            return .blue
        case .pending:
            return .orange
        default:
            assertionFailure("Color for \(self) is not specified")
            return .textSubtle
        }
    }
}

/// Converts the input product model to properties ready to be shown on `ProductsTabProductTableViewCell` and `ProductListSelectorTableViewCell`.
struct ProductsTabProductViewModel {
    let imageUrl: String?
    let name: String
    let productVariation: ProductVariation?
    let detailsAttributedString: NSAttributedString
    let isSelected: Bool
    let isDraggable: Bool

    /// Stock status and variation count or price
    let detailsString: String

    /// SKU for the product if any
    let skuString: String?

    /// Dependency for configuring the view.
    let imageService: ImageService

    init(product: Product,
         productVariation: ProductVariation? = nil,
         isSelected: Bool = false,
         isDraggable: Bool = false,
         imageService: ImageService = ServiceLocator.imageService,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {

        imageUrl = product.images.first?.src
        name = product.name.isEmpty ? Localization.noTitle : product.name
        self.productVariation = productVariation
        self.isSelected = isSelected
        self.isDraggable = isDraggable
        self.imageService = imageService

        let editableProductModel = EditableProductModel(product: product)
        detailsAttributedString = editableProductModel.createDetailsAttributedString()
        detailsString = editableProductModel.createDetailsString(currencySettings: currencySettings)
        skuString = editableProductModel.createSKUString()
    }

    /// Variation will show product variation ID within the title,
    /// Product will only show product name
    /// See more: https://github.com/woocommerce/woocommerce-ios/issues/4846
    /// 
    func createNameLabel() -> String {
        if let variationID = productVariation?.productVariationID {
            // Add product variation ID with name
            return "\(Localization.variationID(variationID: "\(variationID)"))\n\(name)"
        }
        return name
    }
}

private extension EditableProductModel {
    func createDetailsAttributedString() -> NSAttributedString {
        let statusText = createStatusText()
        let stockText = createStockText()
        let variationsText = createVariationsText()

        let detailsText = [statusText, stockText, variationsText]
            .compactMap({ $0 })
            .joined(separator: " • ")

        let attributedString = NSMutableAttributedString(string: detailsText,
                                                         attributes: [
                                                            .foregroundColor: UIColor.textSubtle,
                                                            .font: StyleManager.footerLabelFont
            ])
        if let statusText = statusText {
            attributedString.addAttributes([.foregroundColor: status.descriptionColor],
                                           range: NSRange(location: 0, length: statusText.count))
        }
        return attributedString
    }

    func createDetailsString(currencySettings: CurrencySettings) -> String {
        let stockText = createStockText()
        let variationsText = createVariationsText()
        let priceText = createRegularPriceText(currencySettings: currencySettings)

        return [stockText, variationsText, priceText]
            .compactMap({ $0 })
            .joined(separator: " • ")
    }

    func createRegularPriceText(currencySettings: CurrencySettings) -> String? {
        guard product.price.isNotEmpty else {
            return nil
        }
        let currency = currencySettings.symbol(from: currencySettings.currencyCode)
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        return currencyFormatter.formatAmount(product.price, with: currency)
    }

    func createStatusText() -> String? {
        switch status {
        case .pending, .draft:
            return status.description
        default:
            return nil
        }
    }

    func createVariationsText() -> String? {
        guard !product.variations.isEmpty else {
            return nil
        }
        let numberOfVariations = product.variations.count
        let format = String.pluralize(numberOfVariations,
                                      singular: Localization.VariationCount.singular,
                                      plural: Localization.VariationCount.plural)
        return String.localizedStringWithFormat(format, numberOfVariations)
    }

    func createSKUString() -> String? {
        if let sku = sku, sku.isNotEmpty {
            return String.localizedStringWithFormat(Localization.skuText, sku)
        } else {
            return nil
        }
    }
}

// MARK: Localization
//
private extension EditableProductModel {
    enum Localization {
        static let skuText = NSLocalizedString("SKU: %1$@", comment: "SKU number for a product, reads like: SKU: 32425")
        enum VariationCount {
            static let singular = NSLocalizedString("%1$ld variation",
                                                    comment: "Label about one product variation shown on Products tab. Reads, `1 variation`")
            static let plural = NSLocalizedString("%1$ld variations",
                                                  comment: "Label about number of variations shown on Products tab. Reads, `2 variations`")
        }
    }
}

private extension ProductsTabProductViewModel {
    enum Localization {
        static let noTitle = NSLocalizedString("(No Title)",
                                               comment: "Product title in Products list when there is no title")

        static func variationID(variationID: String) -> String {
            let titleFormat = NSLocalizedString("#%1$@",
                                                comment: "Variation ID. Parameters: %1$@ - Product variation ID")
            return String.localizedStringWithFormat(titleFormat, variationID)
        }
    }
}
