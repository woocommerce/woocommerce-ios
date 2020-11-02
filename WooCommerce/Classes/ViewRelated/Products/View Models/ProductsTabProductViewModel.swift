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

/// Converts the input product model to properties ready to be shown on `ProductsTabProductTableViewCell`.
struct ProductsTabProductViewModel {
    let imageUrl: String?
    let name: String
    let detailsAttributedString: NSAttributedString
    let isSelected: Bool

    // Dependency for configuring the view.
    let imageService: ImageService

    init(product: Product, isSelected: Bool = false, imageService: ImageService = ServiceLocator.imageService) {
        imageUrl = product.images.first?.src
        name = product.name.isEmpty ? Localization.noTitle : product.name
        self.isSelected = isSelected
        detailsAttributedString = EditableProductModel(product: product).createDetailsAttributedString()

        self.imageService = imageService
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
        let singularFormat = NSLocalizedString("%ld variant", comment: "Label about one product variation shown on Products tab")
        let pluralFormat = NSLocalizedString("%ld variants", comment: "Label about number of variations shown on Products tab")
        let format = String.pluralize(numberOfVariations, singular: singularFormat, plural: pluralFormat)
        return String.localizedStringWithFormat(format, numberOfVariations)
    }
}

private extension ProductsTabProductViewModel {
    enum Localization {
        static let noTitle = NSLocalizedString("(No Title)", comment: "Product title in Products list when there is no title")
    }
}
