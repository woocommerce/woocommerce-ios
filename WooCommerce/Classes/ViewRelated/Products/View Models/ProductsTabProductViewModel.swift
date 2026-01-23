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
    let productVariation: ProductVariation?
    let detailsAttributedString: NSAttributedString
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
         imageService: ImageService = ServiceLocator.imageService) {

        imageUrl = product.imageURL?.absoluteString
        name = product.name.isEmpty ? Localization.noTitle : product.name
        self.productVariation = productVariation
        self.isSelected = isSelected
        self.isDraggable = isDraggable
        self.hasPendingUploads = hasPendingUploads
        detailsAttributedString = product.createDetailsAttributedString(isSKUShown: isSKUShown)

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
    func createDetailsAttributedString(isSKUShown: Bool) -> NSAttributedString {
        let statusText = createStatusText()
        let stockText = String.createStockText(productType: productType,
                                               manageStock: manageStock,
                                               stockStatus: productStockStatus,
                                               stockQuantity: stockQuantity,
                                               bundleStockStatus: bundleStockStatus,
                                               bundleStockQuantity: bundleStockQuantity)
        let variationsText = createVariationsText()

        let detailsText = [statusText, stockText, variationsText]
            .compactMap({ $0 })
            .joined(separator: " • ")
        let skuText = isSKUShown ? createSKUText(): nil
        let text = [detailsText, skuText].compactMap { $0 }.joined(separator: "\n")

        let attributedString = NSMutableAttributedString(string: text,
                                                         attributes: [
                                                            .foregroundColor: UIColor.textSubtle,
                                                            .font: StyleManager.footerLabelFont
            ])
        if let statusText = statusText {
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
}

// MARK: Localization
//
private extension EditableProductModel {
    enum Localization {
        enum VariationCount {
            static let singular = NSLocalizedString("%1$ld variation",
                                                    comment: "This text appears as a detail label showing the count of product variations in singular form (e.g., '1 variation') on product listing screens and product edit forms in a WooCommerce mobile app.")
            static let plural = NSLocalizedString("%1$ld variations",
                                                  comment: "This text appears as a label in product variation detail rows and product listings to show the count of variations for variable products, such as '2 variations' or '5 variations'.")
        }
        static let skuFormat = NSLocalizedString("SKU: %1$@", comment: "Label about the SKU of a product in the product list. Reads, `SKU: productSku`")
    }
}

private extension ProductsTabProductViewModel {
    enum Localization {
        static let noTitle = NSLocalizedString("(No Title)",
                                               comment: "This text appears as a placeholder label for products that don't have a title in the product list view of a WooCommerce store management app.")

        static func variationID(variationID: String) -> String {
            let titleFormat = NSLocalizedString("#%1$@",
                                                comment: "A label that displays a product variation ID in the WooCommerce app's product list, formatted with a hashtag prefix followed by the variation identifier (e.g., '#12345').")
            return String.localizedStringWithFormat(titleFormat, variationID)
        }
    }
}
