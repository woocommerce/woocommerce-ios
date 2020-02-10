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
        sections = [ProductSettingsSection(title: Constants.publishFieldsTitle, rows: [.visibility]), ProductSettingsSection(title: Constants.moreOptionsTitle, rows: [.slug])]
    }
}

// MARK: - Register table view cells
//
extension ProductSettingsTableViewModel {
    
    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells(_ tableView: UITableView) {
        for row in ProductSettingsRow.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }
}


extension ProductSettingsTableViewModel {
    struct ProductSettingsSection {
        let title: String?
        let rows: [ProductSettingsRow]
    }
    
    enum ProductSettingsRow: CaseIterable {
        case visibility
        case slug
        
        var type: UITableViewCell.Type {
            switch self {
            case .visibility, .slug:
                return BasicTableViewCell.self
            }
        }
        
        var reuseIdentifier: String {
            return type.reuseIdentifier
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
