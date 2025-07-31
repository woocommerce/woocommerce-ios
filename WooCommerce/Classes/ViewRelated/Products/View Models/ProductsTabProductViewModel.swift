import Foundation
import UIKit
import Yosemite

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

        imageUrl = product.images.first?.src
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
        let stockText = createStockText()
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

    /// Create a description text based on a product data model's stock status/quantity.
    func createStockText() -> String {
        if productType == .bundle {
            return createProductBundleStockText()
        }

        switch productStockStatus {
        case .inStock:
            if let stockQuantity = stockQuantity, manageStock {
                let localizedStockQuantity = NumberFormatter.localizedString(from: stockQuantity as NSDecimalNumber, number: .decimal)
                let format = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown on Products tab")
                return String.localizedStringWithFormat(format, localizedStockQuantity)
            } else {
                return NSLocalizedString("In stock", comment: "Label about product's inventory stock status shown on Products tab")
            }
        default:
            return productStockStatus.description
        }
    }

    /// Create a description text based on a product bundle data model's stock status/quantity and bundle stock status/quantity.
    private func createProductBundleStockText() -> String {
        // Use bundle stock status if it is insufficent stock
        if let bundleStockStatus, bundleStockStatus == .insufficientStock {
            return bundleStockStatus.description
        }

        switch productStockStatus {
        case .inStock:
            let quantityFormat = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown on Products tab")
            if let bundleStockQuantity { // Use bundle stock quantity, if set
                let localizedStockQuantity = NumberFormatter.localizedString(from: NSDecimalNumber(value: bundleStockQuantity), number: .decimal)
                return String.localizedStringWithFormat(quantityFormat, localizedStockQuantity)
            } else if let stockQuantity, manageStock { // Otherwise, use product stock quantity if set and product manages stock
                let localizedStockQuantity = NumberFormatter.localizedString(from: stockQuantity as NSDecimalNumber, number: .decimal)
                return String.localizedStringWithFormat(quantityFormat, localizedStockQuantity)
            } else {
                return NSLocalizedString("In stock", comment: "Label about product's inventory stock status shown on Products tab")
            }
        default:
            return productStockStatus.description
        }
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
