import UIKit
import Yosemite

/// The Product Settings contains 2 sections: Publish Settings and More Options
final class ProductSettingsViewModel {

    let siteID: Int64
    let productID: Int64
    
    private let product: Product
    
    var productSettings: ProductSettings {
        didSet {
            sections = Self.configureSections(productSettings)
        }
    }
    
    private(set) var sections: [ProductSettingsSectionMediator] {
        didSet {
            self.onReload?()
        }
    }

    /// Closures
    /// - `onReload` called when sections data are reloaded/refreshed
    var onReload: (() -> Void)?

    init(product: Product) {
        siteID = product.siteID
        productID = product.productID
        self.product = product
        productSettings = ProductSettings(from: product, password: "")
        sections = Self.configureSections(productSettings)
    }

    func handleCellTap(at indexPath: IndexPath, sourceViewController: UIViewController) {
        let section = sections[indexPath.section]
        let row = section.rows[indexPath.row]
        row.handleTap(sourceViewController: sourceViewController) { [weak self] (settings) in
            guard let self = self else {
                return
            }
            self.productSettings = settings
        }
    }

    func hasUnsavedChanges() -> Bool {
        guard ProductSettings(from: product, password: "") != productSettings else {
            return false
        }
        return true
    }
}

// MARK: Configure sections and rows in Product Settings
//
private extension ProductSettingsViewModel {
    static func configureSections(_ settings: ProductSettings) -> [ProductSettingsSectionMediator] {
        return [ProductSettingsSections.PublishSettings(settings),
                     ProductSettingsSections.MoreOptions(settings)
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
