import UIKit

extension ProductFormSection {
    func reuseIdentifier(at rowIndex: Int) -> String {
        switch self {
        case .primaryFields(let rows):
            let row = rows[rowIndex]
            return row.reuseIdentifier
        case .settings(let rows):
            let row = rows[rowIndex]
            return row.reuseIdentifier
        }
    }
}

/// Represents a row in a table.
protocol ReusableTableRow {
    var reuseIdentifier: String { get }

    /// A table row could be presented by different `UITableViewCell` types, depending on the state.
    var cellTypes: [UITableViewCell.Type] { get }
}

extension ProductFormSection.PrimaryFieldRow: ReusableTableRow {
    var cellTypes: [UITableViewCell.Type] {
        switch self {
        case .images:
            return [ProductImagesHeaderTableViewCell.self, ImageAndTitleAndTextTableViewCell.self]
        case .linkedProductsPromo:
            return [cellType]
        case .name:
            return [LabeledTextViewTableViewCell.self, BasicTableViewCell.self]
        case .variationName:
            return [cellType]
        case .description:
            return [ImageAndTitleAndTextTableViewCell.self, BasicTableViewCell.self]
        case .descriptionAI:
            return [ButtonTableViewCell.self]
        case .learnMoreAboutAI:
            return [TextViewTableViewCell.self]
        case .separator:
            return [SpacerTableViewCell.self]
        case .promoteWithBlaze:
            return [LeftImageTableViewCell.self]
        }
    }

    var reuseIdentifier: String {
        return cellType.reuseIdentifier
    }

    private var cellType: UITableViewCell.Type {
        switch self {
        case .images(_, let isStorePublic, _, _):
            return isStorePublic ? ProductImagesHeaderTableViewCell.self : ImageAndTitleAndTextTableViewCell.self
        case .linkedProductsPromo:
            return FeatureAnnouncementCardCell.self
        case .name(_, let editable, _):
            return editable ? LabeledTextViewTableViewCell.self: BasicTableViewCell.self
        case .variationName:
            return BasicTableViewCell.self
        case .description(let description, _, _):
            return description?.isEmpty == false ? ImageAndTitleAndTextTableViewCell.self: BasicTableViewCell.self
        case .descriptionAI:
            return ButtonTableViewCell.self
        case .learnMoreAboutAI:
            return TextViewTableViewCell.self
        case .separator:
            return SpacerTableViewCell.self
        case .promoteWithBlaze:
            return LeftImageTableViewCell.self
        }
    }
}

extension ProductFormSection.SettingsRow: ReusableTableRow {
    var cellTypes: [UITableViewCell.Type] {
        switch self {
        case .price,
             .customFields,
             .productType,
             .inventory,
             .shipping,
             .addOns,
             .categories,
             .tags,
             .shortDescription,
             .externalURL,
             .sku,
             .groupedProducts,
             .variations,
             .downloadableFiles,
             .linkedProducts,
             .status,
             .noPriceWarning,
             .attributes,
             .bundledProducts,
             .components,
             .subscriptionFreeTrial,
             .subscriptionExpiry,
             .noVariationsWarning,
             .quantityRules:
            return [ImageAndTitleAndTextTableViewCell.self]
        case .reviews:
            return [ProductReviewsTableViewCell.self]
        }
    }

    var reuseIdentifier: String {
        return cellType.reuseIdentifier
    }

    private var cellType: UITableViewCell.Type {
        switch self {
        case .price,
             .customFields,
             .productType,
             .inventory,
             .shipping,
             .addOns,
             .categories,
             .tags,
             .shortDescription,
             .externalURL,
             .sku,
             .groupedProducts,
             .variations,
             .downloadableFiles,
             .linkedProducts,
             .status,
             .noPriceWarning,
             .attributes,
             .bundledProducts,
             .components,
             .subscriptionFreeTrial,
             .subscriptionExpiry,
             .noVariationsWarning,
             .quantityRules:
            return ImageAndTitleAndTextTableViewCell.self
        case .reviews:
            return ProductReviewsTableViewCell.self
        }
    }
}
