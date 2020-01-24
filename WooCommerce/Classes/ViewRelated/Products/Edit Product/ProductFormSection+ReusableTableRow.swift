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
            return [ImageAndTitleAndTextTableViewCell.self, BasicTableViewCell.self]
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
        case .name(let name):
            return name?.isNotEmpty == true ? ImageAndTitleAndTextTableViewCell.self: BasicTableViewCell.self
        case .description(let description):
            return description?.isNotEmpty == true ? ImageAndTitleAndTextTableViewCell.self: BasicTableViewCell.self
        }
    }
}

extension ProductFormSection.SettingsRow: ReusableTableRow {
    var cellTypes: [UITableViewCell.Type] {
        switch self {
        case .price, .inventory, .shipping:
            return [ImageAndTitleAndTextTableViewCell.self]
        }
    }

    var reuseIdentifier: String {
        return cellType.reuseIdentifier
    }

    private var cellType: UITableViewCell.Type {
        switch self {
        case .price, .inventory, .shipping:
            return ImageAndTitleAndTextTableViewCell.self
        }
    }
}
