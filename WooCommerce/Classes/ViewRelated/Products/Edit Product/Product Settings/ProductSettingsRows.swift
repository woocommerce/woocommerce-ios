import UIKit
import Yosemite

// MARK: - Mediators Protocols
//

/// Encapsulates configuration and interaction of a UITableView row.
protocol ProductSettingsRowMediator {

    /// Update the cell UI and bind to events if needed.
    func configure(cell: UITableViewCell, sourceViewController: UIViewController)

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

    struct Status: ProductSettingsRowMediator {
        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell, sourceViewController: UIViewController) {
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

        func configure(cell: UITableViewCell, sourceViewController: UIViewController) {
            guard let cell = cell as? TitleAndValueTableViewCell else {
                return
            }

            let title = Localization.visibility
            cell.updateUI(title: title, value: ProductVisibility(status: settings.status, password: settings.password).description)
            cell.accessoryType = .disclosureIndicator
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
            /// Check if the store is eligible for password editing or is authenticated without WPCom.
            /// If neither condition is met, the cell will not be selectable.
            let passwordProtectedAvailable =  ProductPasswordEligibilityUseCase().isEligibleForNewPasswordEndpoint()
            || ServiceLocator.stores.isAuthenticatedWithoutWPCom == false

            guard passwordProtectedAvailable else {
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

        func configure(cell: UITableViewCell, sourceViewController: UIViewController) {
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

        func configure(cell: UITableViewCell, sourceViewController: UIViewController) {
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

        func configure(cell: UITableViewCell, sourceViewController: UIViewController) {
            guard let cell = cell as? SwitchTableViewCell else {
                return
            }

            let title = Localization.downloadableProduct
            cell.title = title
            cell.isOn = settings.downloadable
            cell.onChange = { newValue in
                //TODO: Add analytics M5
                if newValue == false {
                    self.showConfirmAlert(from: sourceViewController,
                                          onConfirm: { self.settings.downloadable = false },
                                          onCancel: { cell.isOn = true })
                } else {
                    self.settings.downloadable = newValue
                }
            }
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
            // Empty because we don't need to handle the tap on this cell
        }

        func showConfirmAlert(from: UIViewController, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) {
            let alert = UIAlertController(title: Localization.downloadableProductAlertTitle,
                                          message: Localization.downloadableProductAlertHint,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localization.downloadableProductAlertConfirm, style: .default) {_ in
                onConfirm()
            })
            alert.addAction(UIAlertAction(title: Localization.downloadableProductAlertCancel, style: .cancel) {_ in
                onCancel()
            })
            from.present(alert, animated: true)
        }

        let reuseIdentifier: String = SwitchTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [SwitchTableViewCell.self]
    }

    struct ReviewsAllowed: ProductSettingsRowMediator {
        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell, sourceViewController: UIViewController) {
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

        func configure(cell: UITableViewCell, sourceViewController: UIViewController) {
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

        func configure(cell: UITableViewCell, sourceViewController: UIViewController) {
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

        func configure(cell: UITableViewCell, sourceViewController: UIViewController) {
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
        static let status = NSLocalizedString("Status", comment: "Status label in Product Settings")
        static let visibility = NSLocalizedString("Visibility", comment: "Visibility label in Product Settings")
        static let catalogVisibility = NSLocalizedString("Catalog Visibility", comment: "Catalog Visibility label in Product Settings")
        static let virtualProduct = NSLocalizedString("Virtual Product", comment: "Virtual Product label in Product Settings")
        static let downloadableProduct = NSLocalizedString("Downloadable Product", comment: "Downloadable Product label in Product Settings")
        static let downloadableProductAlertTitle = NSLocalizedString(
            "productSettings.downloadableProductAlertTitle",
            value: "Are you sure you want to remove the ability to download files when product is purchased?",
            comment: "Confirm the change to make the product non downloadable"
        )
        static let downloadableProductAlertHint = NSLocalizedString(
            "productSettings.downloadableProductAlertHint",
            value: "All files currently attached to this product will be removed.",
            comment: "Confirm the change to make the product non downloadable"
        )
        static let downloadableProductAlertConfirm = NSLocalizedString(
            "productSettings.downloadableProductAlertConfirm",
            value: "Yes, change",
            comment: "Confirm button in the product downloadables alert"
        )
        static let downloadableProductAlertCancel = NSLocalizedString(
            "productSettings.downloadableProductAlertCancel",
            value: "Cancel",
            comment: "Cancel button in the product downloadables alert"
        )
        static let enableReviews = NSLocalizedString("Enable Reviews", comment: "Enable Reviews label in Product Settings")
        static let slug = NSLocalizedString("Slug", comment: "Slug label in Product Settings")
        static let purchaseNote = NSLocalizedString("Purchase Note", comment: "Purchase note label in Product Settings")
        static let menuOrder = NSLocalizedString("Menu Order", comment: "Menu order label in Product Settings")
    }
}
