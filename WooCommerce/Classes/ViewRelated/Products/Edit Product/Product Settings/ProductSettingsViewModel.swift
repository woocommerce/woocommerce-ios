import UIKit
import Yosemite

/// The Product Settings contains 2 sections: Publish Settings and More Options
struct ProductSettingsViewModel {

    let sections: [ProductSettingsSectionMediator]

    init(product: Product) {
        sections = Self.configureSections(product)
    }
}

// MARK: Configure sections and rows in Product Settings
//
private extension ProductSettingsViewModel {
    static func configureSections(_ product: Product) -> [ProductSettingsSectionMediator] {
        return [ProductSettingsSections.PublishSettings(product),
                     ProductSettingsSections.MoreOptions(product)
        ]
    }
}

// MARK: - Register table view cells and headers
//
extension ProductSettingsViewModel {

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells(_ tableView: UITableView) {
        sections.flatMap {
            $0.rows.flatMap { $0.cellTypes }
        }.forEach {
            tableView.register($0.loadNib(), forCellReuseIdentifier: $0.reuseIdentifier)
        }
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters(_ tableView: UITableView) {
        let headersAndFooters = [TwoColumnSectionHeaderView.self]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }
}
