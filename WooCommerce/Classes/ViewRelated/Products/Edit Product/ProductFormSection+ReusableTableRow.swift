import UIKit

extension ProductFormSection {
    func reuseIdentifier(at rowIndex: Int) -> String {
        switch self {
        case .primaryFields(let rows):
            let row = rows[rowIndex]
            return row.reuseIdentifier
        default:
            fatalError("Not implemented yet")
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
        case .description:
            return [ImageAndTitleAndTextTableViewCell.self, BasicTableViewCell.self]
        default:
            fatalError("Not implemented yet")
        }
    }

    var reuseIdentifier: String {
        return cellType.reuseIdentifier
    }

    private var cellType: UITableViewCell.Type {
        switch self {
        case .description(let description):
            return description?.isEmpty == false ? ImageAndTitleAndTextTableViewCell.self: BasicTableViewCell.self
        default:
            fatalError("Not implemented yet")
        }
    }
}
