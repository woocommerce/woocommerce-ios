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
            return [ProductImagesHeaderTableViewCell.self]
        case .name:
            return [TextFieldTableViewCell.self]
        case .variationName:
            return [cellType]
        case .description:
            return [ImageAndTitleAndTextTableViewCell.self, BasicTableViewCell.self]
        }
    }

    var reuseIdentifier: String {
        return cellType.reuseIdentifier
    }

    private var cellType: UITableViewCell.Type {
        switch self {
        case .images:
            return ProductImagesHeaderTableViewCell.self
        case .name:
            return TextFieldTableViewCell.self
        case .variationName:
            return BasicTableViewCell.self
        case .description(let description):
            return description?.isEmpty == false ? ImageAndTitleAndTextTableViewCell.self: BasicTableViewCell.self
        }
    }
}

extension ProductFormSection.SettingsRow: ReusableTableRow {
    var cellTypes: [UITableViewCell.Type] {
        switch self {
        case .price, .inventory, .shipping, .categories, .tags, .briefDescription, .externalURL, .sku, .groupedProducts, .variations:
            return [ImageAndTitleAndTextTableViewCell.self]
        }
    }

    var reuseIdentifier: String {
        return cellType.reuseIdentifier
    }

    private var cellType: UITableViewCell.Type {
        switch self {
        case .price, .inventory, .shipping, .categories, .tags, .briefDescription, .externalURL, .sku, .groupedProducts, .variations:
            return ImageAndTitleAndTextTableViewCell.self
        }
    }
}
