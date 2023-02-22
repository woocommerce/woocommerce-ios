import UIKit
import Yosemite

// MARK: - Mediators Protocols
//

/// Encapsulates configuration and interaction of a UITableView row.
protocol ProductSettingsRowMediator {

    /// Update the cell UI and bind to events if needed.
    func configure(cell: UITableViewCell)

    /// Show a reusable ViewController like AztecEditorViewController.
    ///
    func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (_ settings: ProductSettings) -> Void)

    var reuseIdentifier: String { get }

    /// A table row could be presented by different `UITableViewCell` types, depending on the state.
    var cellTypes: [UITableViewCell.Type] { get }

    init(_ settings: ProductSettings)
}


// MARK: - Rows declaration for Product Settings
//
enum ProductSettingsRows {

    struct ProductType: ProductSettingsRowMediator {
        private let settings: ProductSettings
        private let supportedTypes: [Yosemite.ProductType] = [.simple, .affiliate, .grouped, .variable]

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? TitleAndValueTableViewCell else {
                return
            }

            if supportedTypes.contains(settings.productType) {
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                cell.apply(style: .regular)
            } else {
                cell.accessoryType = .none
                cell.selectionStyle = .none
                cell.apply(style: .nonSelectable)
            }

            let details: String
            switch settings.productType {
            case .simple:
                switch (settings.downloadable, settings.virtual) {
                case (true, _):
                    details = Localization.downloadableProductType
                case (false, true):
                    details = Localization.virtualProductType
                case (false, false):
                    details = Localization.physicalProductType
                }
            case .custom(let customProductType):
                // Custom product type description is the slug, thus we replace the dash with space and capitalize the string.
                details = customProductType.description.replacingOccurrences(of: "-", with: " ").capitalized
            default:
                details = settings.productType.description
            }

            cell.updateUI(title: Localization.productType, value: details)
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
            guard supportedTypes.contains(settings.productType) else {
                return
            }

            let viewProperties = BottomSheetListSelectorViewProperties(subtitle: Localization.productTypeSheetTitle)
            let productType = BottomSheetProductType(productType: settings.productType, isVirtual: settings.virtual)
            let command = ProductTypeBottomSheetListSelectorCommand(selected: productType) { selectedProductType in
                sourceViewController.dismiss(animated: true, completion: nil)

                let originalProductType = settings.productType

                ServiceLocator.analytics.track(.productTypeChanged, withProperties: [
                    "from": originalProductType.rawValue,
                    "to": selectedProductType.productType.rawValue
                ])

                presentProductTypeChangeAlert(for: originalProductType, on: sourceViewController, completion: { change in
                    guard change else {
                        return
                    }

                    self.settings.productType = selectedProductType.productType
                    self.settings.virtual = selectedProductType.isVirtual
                    onCompletion(self.settings)
                })
            }
            let productTypesListPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties, command: command)
            productTypesListPresenter.show(from: sourceViewController)
        }

        /// Product Type Change alert
        ///
        private func presentProductTypeChangeAlert(for productType: Yosemite.ProductType, on vc: UIViewController, completion: @escaping (Bool) -> ()) {
            let body: String
            switch productType {
            case .variable:
                body = Localization.Alert.productVariableTypeChangeMessage
            default:
                body = Localization.Alert.productTypeChangeMessage
            }

            let alertController = UIAlertController(title: Localization.Alert.productTypeChangeTitle,
                                                    message: body,
                                                    preferredStyle: .alert)
            let cancel = UIAlertAction(title: Localization.Alert.productTypeChangeCancelButton,
                                       style: .cancel) { (action) in
                                           completion(false)
                                       }
            let confirm = UIAlertAction(title: Localization.Alert.productTypeChangeConfirmButton,
                                        style: .default) { (action) in
                                            completion(true)
                                        }
            alertController.addAction(cancel)
            alertController.addAction(confirm)
            vc.present(alertController, animated: true)
        }

        let reuseIdentifier: String = TitleAndValueTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [TitleAndValueTableViewCell.self]
    }

    struct Status: ProductSettingsRowMediator {
        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? TitleAndValueTableViewCell else {
                return
            }

            /// If the status is private, the status cell becomes not editable.
            if isStatusPrivate() {
                cell.accessoryType = .none
                cell.selectionStyle = .none
                cell.apply(style: .nonSelectable)
            }
            else {
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                cell.apply(style: .regular)
            }

            cell.updateUI(title: Localization.status, value: settings.status.description)
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {

            /// If the status is private, the cell doesn't trigger any action
            guard !isStatusPrivate() else {
                return
            }

            ServiceLocator.analytics.track(.productSettingsStatusTapped)
            let command = ProductStatusSettingListSelectorCommand(selected: settings.status)

            let listSelectorViewController = ListSelectorViewController(command: command) { selected in

                                                                            self.settings.status = selected ?? self.settings.status
                                                                            onCompletion(self.settings)
            }
            sourceViewController.navigationController?.pushViewController(listSelectorViewController, animated: true)

        }

        let reuseIdentifier: String = TitleAndValueTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [TitleAndValueTableViewCell.self]

        /// Utils
        func isStatusPrivate() -> Bool {
            return settings.status == .privateStatus
        }
    }

    struct Visibility: ProductSettingsRowMediator {

        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? TitleAndValueTableViewCell else {
                return
            }

            let title = Localization.visibility
            cell.updateUI(title: title, value: ProductVisibility(status: settings.status, password: settings.password).description)
            cell.accessoryType = .disclosureIndicator
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
            let passwordProtectedAvailable = ServiceLocator.stores.isAuthenticatedWithoutWPCom == false
            /// If the password was not fetched for user authenticated with WPCom,
            /// the cell is not selectable
            if settings.password == nil && passwordProtectedAvailable {
                return
            }

            ServiceLocator.analytics.track(.productSettingsVisibilityTapped)
            let viewController = ProductVisibilityViewController(
                settings: settings,
                showsPasswordProtectedVisibility: passwordProtectedAvailable
            ) { (productSettings) in
                self.settings.password = productSettings.password
                self.settings.status = productSettings.status
                onCompletion(self.settings)
            }
            sourceViewController.navigationController?.pushViewController(viewController, animated: true)
        }

        let reuseIdentifier: String = TitleAndValueTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [TitleAndValueTableViewCell.self]
    }

    struct CatalogVisibility: ProductSettingsRowMediator {

        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? TitleAndValueTableViewCell else {
                return
            }

            let title = Localization.catalogVisibility
            cell.updateUI(title: title, value: settings.catalogVisibility.description)
            cell.accessoryType = .disclosureIndicator
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
            ServiceLocator.analytics.track(.productSettingsCatalogVisibilityTapped)
            let viewController = ProductCatalogVisibilityViewController(settings: settings) { (productSettings) in
                self.settings.featured = productSettings.featured
                self.settings.catalogVisibility = productSettings.catalogVisibility
                onCompletion(self.settings)
            }
            sourceViewController.navigationController?.pushViewController(viewController, animated: true)
        }

        let reuseIdentifier: String = TitleAndValueTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [TitleAndValueTableViewCell.self]
    }

    struct VirtualProduct: ProductSettingsRowMediator {
        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? SwitchTableViewCell else {
                return
            }

            let title = Localization.virtualProduct
            cell.title = title
            cell.isOn = settings.virtual
            cell.onChange = { newValue in
                ServiceLocator.analytics.track(.productSettingsVirtualToggled)
                self.settings.virtual = newValue
            }
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
            // Empty because we don't need to handle the tap on this cell
        }

        let reuseIdentifier: String = SwitchTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [SwitchTableViewCell.self]
    }

    struct DownloadableProduct: ProductSettingsRowMediator {
         private let settings: ProductSettings

          init(_ settings: ProductSettings) {
             self.settings = settings
         }

          func configure(cell: UITableViewCell) {
             guard let cell = cell as? SwitchTableViewCell else {
                 return
             }

            let title = Localization.downloadableProduct
             cell.title = title
             cell.isOn = settings.downloadable
             cell.onChange = { newValue in
                 //TODO: Add analytics M5
                 self.settings.downloadable = newValue
             }
         }

          func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
             // Empty because we don't need to handle the tap on this cell
         }

          let reuseIdentifier: String = SwitchTableViewCell.reuseIdentifier

          let cellTypes: [UITableViewCell.Type] = [SwitchTableViewCell.self]
     }

    struct ReviewsAllowed: ProductSettingsRowMediator {
        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? SwitchTableViewCell else {
                return
            }

            let title = Localization.enableReviews
            cell.title = title
            cell.isOn = settings.reviewsAllowed
            cell.onChange = { newValue in
                ServiceLocator.analytics.track(.productSettingsReviewsToggled)
                self.settings.reviewsAllowed = newValue
            }
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
            // Empty because we don't need to handle the tap on this cell
        }

        let reuseIdentifier: String = SwitchTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [SwitchTableViewCell.self]
    }

    struct Slug: ProductSettingsRowMediator {
        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? TitleAndValueTableViewCell else {
                return
            }

            let title = Localization.slug
            cell.updateUI(title: title, value: settings.slug)
            cell.accessoryType = .disclosureIndicator
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
            ServiceLocator.analytics.track(.productSettingsSlugTapped)
            let viewController = ProductSlugViewController(settings: settings) { (productSettings) in
                self.settings.slug = productSettings.slug
                onCompletion(self.settings)
            }
            sourceViewController.navigationController?.pushViewController(viewController, animated: true)
        }

        let reuseIdentifier: String = TitleAndValueTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [TitleAndValueTableViewCell.self]
    }

    struct PurchaseNote: ProductSettingsRowMediator {
        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? TitleAndValueTableViewCell else {
                return
            }

            let title = Localization.purchaseNote
            cell.updateUI(title: title, value: settings.purchaseNote?.strippedHTML)
            cell.accessoryType = .disclosureIndicator
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
            ServiceLocator.analytics.track(.productSettingsPurchaseNoteTapped)
            let viewController = ProductPurchaseNoteViewController(settings: settings) { (productSettings) in
                self.settings.purchaseNote = productSettings.purchaseNote
                onCompletion(self.settings)
            }
            sourceViewController.navigationController?.pushViewController(viewController, animated: true)
        }

        let reuseIdentifier: String = TitleAndValueTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [TitleAndValueTableViewCell.self]
    }

    struct MenuOrder: ProductSettingsRowMediator {
        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? TitleAndValueTableViewCell else {
                return
            }

            let title = Localization.menuOrder
            cell.updateUI(title: title, value: String(settings.menuOrder))
            cell.accessoryType = .disclosureIndicator
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
            ServiceLocator.analytics.track(.productSettingsMenuOrderTapped)
            let viewController = ProductMenuOrderViewController(settings: settings) { (productSettings) in
                self.settings.menuOrder = productSettings.menuOrder
                onCompletion(self.settings)
            }
            sourceViewController.navigationController?.pushViewController(viewController, animated: true)
        }

        let reuseIdentifier: String = TitleAndValueTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [TitleAndValueTableViewCell.self]
    }
}

extension ProductSettingsRows {
    enum Localization {
        // Product Type
        static let productType = NSLocalizedString("Product Type", comment: "Product Type label in Product Settings")
        static let downloadableProductType = NSLocalizedString("Downloadable",
                                                               comment: "Display label for simple downloadable product type.")
        static let virtualProductType = NSLocalizedString("Virtual",
                                                          comment: "Display label for simple virtual product type.")
        static let physicalProductType = NSLocalizedString("Physical",
                                                           comment: "Display label for simple physical product type.")
        static let productTypeSheetTitle = NSLocalizedString("Change product type",
                                                             comment: "Message title of bottom sheet for selecting a product type")

        static let status = NSLocalizedString("Status", comment: "Status label in Product Settings")
        static let visibility = NSLocalizedString("Visibility", comment: "Visibility label in Product Settings")
        static let catalogVisibility = NSLocalizedString("Catalog Visibility", comment: "Catalog Visibility label in Product Settings")
        static let virtualProduct = NSLocalizedString("Virtual Product", comment: "Virtual Product label in Product Settings")
        static let downloadableProduct = NSLocalizedString("Downloadable Product", comment: "Downloadable Product label in Product Settings")
        static let enableReviews = NSLocalizedString("Enable Reviews", comment: "Enable Reviews label in Product Settings")
        static let slug = NSLocalizedString("Slug", comment: "Slug label in Product Settings")
        static let purchaseNote = NSLocalizedString("Purchase Note", comment: "Purchase note label in Product Settings")
        static let menuOrder = NSLocalizedString("Menu Order", comment: "Menu order label in Product Settings")

        enum Alert {
            // Product type change
            static let productTypeChangeTitle = NSLocalizedString("Are you sure you want to change the product type?",
                                                                  comment: "Title of the alert when a user is changing the product type")
            static let productTypeChangeMessage = NSLocalizedString("Changing the product type will modify some of the product data",
                                                                    comment: "Body of the alert when a user is changing the product type")
            static let productVariableTypeChangeMessage =
                NSLocalizedString("Changing the product type will modify some of the product data and delete all your attributes and variations",
                                  comment: "Body of the alert when a user is changing the product type")

            static let productTypeChangeCancelButton =
                NSLocalizedString("Cancel", comment: "Cancel button on the alert when the user is cancelling the action on changing product type")
            static let productTypeChangeConfirmButton = NSLocalizedString("Yes, change",
                                                                          comment: "Confirmation button on the alert when the user is changing product type")
        }
    }
}
