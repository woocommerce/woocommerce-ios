import Foundation
import UIKit
import Yosemite
import WooFoundation

private extension ProductStatus {
    var descriptionColor: UIColor {
        switch self {
        case .draft:
            return .wooBlue
        case .pending:
            return .orange
        case .privateStatus:
            return .wooBlue
        default:
            assertionFailure("Color for \(self) is not specified")
            return .textSubtle
        }
    }
}

/// Converts the input product model to properties ready to be shown on `ProductsTabProductTableViewCell`.
struct ProductsTabProductViewModel {
    let imageUrl: String?
    let name: String
    let stockStatusKey: String
    let productVariation: ProductVariation?
    let detailsAttributedString: NSAttributedString
    /// Draft, pending or private; `nil` for published products.
    let statusText: String?
    /// Stock, price and variations, without the status.
    let detailsText: String
    let skuText: String?
    let isSelected: Bool
    let isDraggable: Bool
    let hasPendingUploads: Bool

    // Dependency for configuring the view.
    let imageService: ImageService

    init(product: ProductListItem,
         hasPendingUploads: Bool = false,
         productVariation: ProductVariation? = nil,
         isSelected: Bool = false,
         isDraggable: Bool = false,
         isSKUShown: Bool = false,
         isPriceShown: Bool = false,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         imageService: ImageService = ServiceLocator.imageService) {

        stockStatusKey = product.stockStatusKey
        imageUrl = product.imageURL?.absoluteString
        name = product.name.isEmpty ? Localization.noTitle : product.name
        self.productVariation = productVariation
        self.isSelected = isSelected
        self.isDraggable = isDraggable
        self.hasPendingUploads = hasPendingUploads
        statusText = product.createStatusText()
        detailsText = product.createDetailsText(isPriceShown: isPriceShown, currencySettings: currencySettings)
        skuText = isSKUShown ? product.createSKUText() : nil
        detailsAttributedString = product.createDetailsAttributedString(statusText: statusText, detailsText: detailsText, skuText: skuText)

        self.imageService = imageService
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

private extension ProductListItem {
    func createDetailsText(isPriceShown: Bool, currencySettings: CurrencySettings) -> String {
        let stockText = String.createStockText(productType: productType,
                                               manageStock: manageStock,
                                               stockStatus: productStockStatus,
                                               stockQuantity: stockQuantity,
                                               bundleStockStatus: bundleStockStatus,
                                               bundleStockQuantity: bundleStockQuantity)
        let priceText = isPriceShown ? createPriceText(currencySettings: currencySettings): nil
        let variationsText = createVariationsText()
        return [stockText, priceText, variationsText]
            .compactMap({ $0 })
            .joined(separator: " • ")
    }

    func createDetailsAttributedString(statusText: String?, detailsText: String, skuText: String?) -> NSAttributedString {
        let statusAndDetailsText = [statusText, detailsText]
            .compactMap({ $0 })
            .joined(separator: " • ")
        let text = [statusAndDetailsText, skuText].compactMap { $0 }.joined(separator: "\n")

        let attributedString = NSMutableAttributedString(string: text,
                                                         attributes: [
                                                            .foregroundColor: UIColor.textSubtle,
                                                            .font: StyleManager.footerLabelFont
                                                         ])
        if let statusText {
            attributedString.addAttributes([.foregroundColor: productStatus.descriptionColor],
                                           range: NSRange(location: 0, length: statusText.count))
        }
        return attributedString
    }

    func createStatusText() -> String? {
        switch productStatus {
        case .pending, .draft, .privateStatus:
            return productStatus.description
        default:
            return nil
        }
    }

    func createVariationsText() -> String? {
        guard !variations.isEmpty else {
            return nil
        }
        let numberOfVariations = variations.count
        let format = String.pluralize(numberOfVariations,
                                      singular: EditableProductModel.Localization.VariationCount.singular,
                                      plural: EditableProductModel.Localization.VariationCount.plural)
        return String.localizedStringWithFormat(format, numberOfVariations)
    }

    func createSKUText() -> String? {
        guard let sku, sku.isNotEmpty else {
            return nil
        }
        return String.localizedStringWithFormat(EditableProductModel.Localization.skuFormat, sku)
    }

    func createPriceText(currencySettings: CurrencySettings) -> String? {
        guard price.isNotEmpty else {
            return nil
        }
        return CurrencyFormatter(currencySettings: currencySettings).formatAmount(price)
    }
}

// MARK: Localization
//
private extension EditableProductModel {
    enum Localization {
        enum VariationCount {
            static let singular = NSLocalizedString("%1$ld variation",
                                                    comment: "Label about one product variation shown on Products tab. Reads, `1 variation`")
            static let plural = NSLocalizedString("%1$ld variations",
                                                  comment: "Label about number of variations shown on Products tab. Reads, `2 variations`")
        }
        static let skuFormat = NSLocalizedString("SKU: %1$@", comment: "Label about the SKU of a product in the product list. Reads, `SKU: productSku`")
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
