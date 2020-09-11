import UIKit
import Yosemite

/// The Product Settings contains 2 sections: Publish Settings and More Options
final class ProductSettingsViewModel {

    private let product: Product

    /// The original password, the one fetched from site post API
    private var password: String?

    var productSettings: ProductSettings {
        didSet {
            sections = Self.configureSections(productSettings, productType: product.productType, isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)
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

    private let isEditProductsRelease3Enabled: Bool

    init(product: Product, password: String?, formType: ProductFormType, isEditProductsRelease3Enabled: Bool) {
        self.product = product
        self.password = password
        self.isEditProductsRelease3Enabled = isEditProductsRelease3Enabled
        productSettings = ProductSettings(from: product, password: password)

        switch formType {
        case .add:
            self.password = ""
            productSettings.password = ""
            sections = Self.configureSections(productSettings, productType: product.productType, isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)
        case .edit:
            sections = Self.configureSections(productSettings, productType: product.productType, isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)
            /// If nil, we fetch the password from site post API because it was never fetched
            if password == nil {
                retrieveProductPassword(siteID: product.siteID, productID: product.productID) { [weak self] (password, error) in
                    guard let self = self else {
                        return
                    }
                    guard error == nil, let password = password else {
                        return
                    }
                    self.onPasswordRetrieved?(password)
                    self.password = password
                    self.productSettings.password = password
                    self.sections = Self.configureSections(self.productSettings,
                                                           productType: product.productType,
                                                           isEditProductsRelease3Enabled: self.isEditProductsRelease3Enabled)
                }
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
    func retrieveProductPassword(siteID: Int64, productID: Int64, onCompletion: ((String?, Error?) -> ())? = nil) {
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
    static func configureSections(_ settings: ProductSettings,
                                  productType: ProductType,
                                  isEditProductsRelease3Enabled: Bool) -> [ProductSettingsSectionMediator] {
        return [ProductSettingsSections.PublishSettings(settings, productType: productType, isEditProductsRelease3Enabled: isEditProductsRelease3Enabled),
                ProductSettingsSections.MoreOptions(settings, productType: productType, isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)
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
