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

protocol ReusableTableCell {
    var reuseIdentifier: String { get }
    var cellType: UITableViewCell.Type { get }
}

extension ProductFormSection.PrimaryFieldRow: ReusableTableCell {
    var cellType: UITableViewCell.Type {
        switch self {
        case .description:
            return PlaceholderOrTitleAndTextTableViewCell.self
        default:
            fatalError("Not implemented yet")
        }
    }

    var reuseIdentifier: String {
        return cellType.reuseIdentifier
    }
}
