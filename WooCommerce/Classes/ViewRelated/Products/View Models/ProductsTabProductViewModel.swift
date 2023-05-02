import Foundation
import Yosemite
import WooFoundation

private extension ProductStatus {
    var descriptionColor: UIColor {
        switch self {
        case .draft:
            return .wooBlue
        case .pending:
            return .orange
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

    // Dependency for configuring the view.
    let imageService: ImageService

    init(product: Product,
         productVariation: ProductVariation? = nil,
         isSelected: Bool = false,
         isDraggable: Bool = false,
         isSKUShown: Bool = false,
         imageService: ImageService = ServiceLocator.imageService,
         productBundlesEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.productBundles)) {

        imageUrl = product.images.first?.src
        name = product.name.isEmpty ? Localization.noTitle : product.name
        self.productVariation = productVariation
        self.isSelected = isSelected
        self.isDraggable = isDraggable
        detailsAttributedString = EditableProductModel(product: product).createDetailsAttributedString(isSKUShown: isSKUShown,
                                                                                                       productBundlesEnabled: productBundlesEnabled)

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

private extension EditableProductModel {
    func createDetailsAttributedString(isSKUShown: Bool, productBundlesEnabled: Bool) -> NSAttributedString {
        let statusText = createStatusText()
        let stockText = createStockText(productBundlesEnabled: productBundlesEnabled)
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
            attributedString.addAttributes([.foregroundColor: status.descriptionColor],
                                           range: NSRange(location: 0, length: statusText.count))
        }
        return attributedString
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

    func createSKUText() -> String? {
        guard let sku = product.sku, sku.isNotEmpty else {
            return nil
        }
        return String.localizedStringWithFormat(Localization.skuFormat, sku)
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
