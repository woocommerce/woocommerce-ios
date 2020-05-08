import UIKit
import Yosemite

/// The Product Settings contains 2 sections: Publish Settings and More Options
final class ProductSettingsViewModel {

    let siteID: Int64
    let productID: Int64

    private let product: Product

    /// The original password, the one fetched from site post API
    private var password: String?

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
    /// - `onPasswordRetrieved` called when the password is fetched
    var onReload: (() -> Void)?
    var onPasswordRetrieved: ((_ password: String) -> Void)?

    init(product: Product, password: String?) {
        siteID = product.siteID
        productID = product.productID
        self.product = product
        self.password = password
        productSettings = ProductSettings(from: product, password: password)
        sections = Self.configureSections(productSettings)

        /// If nil, we fetch the password from site post API because it was never fetched
        if password == nil {
            retrieveProductPassword { [weak self] (password, error) in
                guard let self = self else {
                    return
                }
                guard error == nil, let password = password else {
                    return
                }
                self.onPasswordRetrieved?(password)
                self.password = password
                self.productSettings.password = password
                self.sections = Self.configureSections(self.productSettings)
            }
        }
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
        guard ProductSettings(from: product, password: password) != productSettings else {
            return false
        }
        return true
    }
}

// MARK: Syncing data. Yosemite related stuff
private extension ProductSettingsViewModel {
    func retrieveProductPassword(onCompletion: ((String?, Error?) -> ())? = nil) {
        let action = SitePostAction.retrieveSitePostPassword(siteID: siteID, postID: productID) { (password, error) in
            guard let _ = password else {
                DDLogError("⛔️ Error fetching product password: \(error.debugDescription)")
                onCompletion?(nil, error)
                return
            }

            onCompletion?(password, nil)
        }

        ServiceLocator.stores.dispatch(action)
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
