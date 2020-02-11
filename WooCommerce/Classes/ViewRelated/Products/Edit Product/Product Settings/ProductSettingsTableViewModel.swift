import UIKit
import Yosemite

/// The Product Settings contains 2 sections: Publish Settings and More Options
struct ProductSettingsTableViewModel {

    private(set) var sections: [ProductSettingsSection] = []
    
    init(product: Product) {
        configureSections(product: product)
    }
    
}

// MARK: Configure sections and rows in Product Settings
//
private extension ProductSettingsTableViewModel {
    mutating func configureSections(product: Product) {
        sections = [.publishSettings(title: Constants.publishFieldsTitle, rows: configurePublishSettingsRows(product)),
        .moreOptions(title: Constants.moreOptionsTitle, rows: configureMoreOptionsRows(product))]
    }
    
    func configurePublishSettingsRows(_ product: Product) -> [ProductSettingsSection.PublishSettingsRow] {
        return [.visibility(product.catalogVisibilityKey)]
    }
    
    func configureMoreOptionsRows(_ product: Product) -> [ProductSettingsSection.MoreOptionsRow] {
        return [.slug(product.slug)]
    }
}

// MARK: - Register table view cells and headers
//
extension ProductSettingsTableViewModel {
    
    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells(_ tableView: UITableView) {
        sections.forEach { section in
            switch section {
            case .publishSettings( _, let rows):
                rows.forEach { row in
                    row.cellTypes.forEach { cellType in
                        tableView.register(cellType.loadNib(), forCellReuseIdentifier: cellType.reuseIdentifier)
                    }
                }
            case .moreOptions( _, let rows):
                rows.forEach { row in
                    row.cellTypes.forEach { cellType in
                        tableView.register(cellType.loadNib(), forCellReuseIdentifier: cellType.reuseIdentifier)
                    }
                }
            }
        }
    }
}

private extension ProductSettingsTableViewModel {
    enum Constants {
        static let publishFieldsTitle = NSLocalizedString("Publish Settings",
                                                          comment: "Title of the Publish Settings section on Product Settings screen")
        static let moreOptionsTitle = NSLocalizedString("More Options",
                                                        comment: "Title of the More Options section on Product Settings screen")
    }
}


enum ProductSettingsSection {
    case publishSettings(title: String?, rows: [PublishSettingsRow])
    case moreOptions(title: String?, rows: [MoreOptionsRow])
    
    enum PublishSettingsRow {
        case visibility(_ visibility: String?)
    }
    
    enum MoreOptionsRow {
        case slug(_ slug: String?)
    }
}

extension ProductSettingsSection {
    func reuseIdentifier(at rowIndex: Int) -> String {
        switch self {
        case .publishSettings( _, let rows):
            let row = rows[rowIndex]
            return row.reuseIdentifier
        case .moreOptions( _, let rows):
            let row = rows[rowIndex]
            return row.reuseIdentifier
        }
    }
}

extension ProductSettingsSection.PublishSettingsRow: ReusableTableRow {
    var cellTypes: [UITableViewCell.Type] {
        switch self {
        case .visibility:
            return [BasicTableViewCell.self]
        }
    }

    var reuseIdentifier: String {
        return cellType.reuseIdentifier
    }
    
    private var cellType: UITableViewCell.Type {
        switch self {
        case .visibility:
            return BasicTableViewCell.self
        }
    }
}

extension ProductSettingsSection.MoreOptionsRow: ReusableTableRow {
    var cellTypes: [UITableViewCell.Type] {
        switch self {
        case .slug:
            return [BasicTableViewCell.self]
        }
    }

    var reuseIdentifier: String {
        return cellType.reuseIdentifier
    }
    
    private var cellType: UITableViewCell.Type {
        switch self {
        case .slug:
            return BasicTableViewCell.self
        }
    }
}

//extension ProductSettingsSection {
//    func reuseIdentifier(at rowIndex: Int) -> String {
//        switch self {
//        case .primaryFields(let rows):
//            let row = rows[rowIndex]
//            return row.reuseIdentifier
//        case .settings(let rows):
//            let row = rows[rowIndex]
//            return row.reuseIdentifier
//        }
//    }
//}
