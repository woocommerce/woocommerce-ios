import UIKit
import Yosemite

/// The Product Settings contains 2 sections: Publish Settings and More Options
final class ProductSettingsViewModel {

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

    init(product: Product,
         password: String?,
         formType: ProductFormType) {
        self.product = product
        self.password = password
        productSettings = ProductSettings(from: product, password: password)

        switch formType {
        case .add:
            self.password = ""
            productSettings.password = ""
            sections = Self.configureSections(productSettings)
        case .edit:
            sections = Self.configureSections(productSettings)

            /// if store has WC 8.1 or above, we use the `password` field in Product model.
            if ProductPasswordEligibilityUseCase().isEligibleForWooProductPasswordEndpoint() {
                guard let productPassword = product.password else {
                    return
                }
                self.onPasswordRetrieved?(productPassword)
                self.password = productPassword
                self.productSettings.password = productPassword
                self.sections = Self.configureSections(self.productSettings)
            }
            /// If user is not on WC 8.1, and if the password is empty/nil,
            /// and user is authenticated with WP.com, enter here, otherwise we skip this.
            else if (product.password == nil || product.password?.isEmpty == true) && ServiceLocator.stores.isAuthenticatedWithoutWPCom == false {
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
                    self.sections = Self.configureSections(self.productSettings)
                }
            }
        case .readonly:
            sections = Self.configureSections(productSettings)
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
            tableView.registerNib(for: $0)
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
