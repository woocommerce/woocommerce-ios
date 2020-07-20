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

    struct Status: ProductSettingsRowMediator {
        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? SettingTitleAndValueTableViewCell else {
                return
            }

            /// If the status is private, the status cell becomes not editable.
            if isStatusPrivate() {
                cell.accessoryType = .none
                cell.selectionStyle = .none
                cell.applyNonSelectableLabelsStyle()
            }
            else {
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                cell.applyDefaultLabelsStyle()
            }

            cell.updateUI(title: NSLocalizedString("Status", comment: "Status label in Product Settings"), value: settings.status.description)
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

        let reuseIdentifier: String = SettingTitleAndValueTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [SettingTitleAndValueTableViewCell.self]

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
            guard let cell = cell as? SettingTitleAndValueTableViewCell else {
                return
            }

            let title = NSLocalizedString("Visibility", comment: "Visibility label in Product Settings")
            cell.updateUI(title: title, value: ProductVisibility(status: settings.status, password: settings.password).description)
            cell.accessoryType = .disclosureIndicator
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
            // If the password was not fetched, the cell is not selectable
            guard settings.password != nil else {
                return
            }

            ServiceLocator.analytics.track(.productSettingsVisibilityTapped)
            let viewController = ProductVisibilityViewController(settings: settings) { (productSettings) in
                self.settings.password = productSettings.password
                self.settings.status = productSettings.status
                onCompletion(self.settings)
            }
            sourceViewController.navigationController?.pushViewController(viewController, animated: true)
        }

        let reuseIdentifier: String = SettingTitleAndValueTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [SettingTitleAndValueTableViewCell.self]
    }

    struct CatalogVisibility: ProductSettingsRowMediator {

        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? SettingTitleAndValueTableViewCell else {
                return
            }

            let title = NSLocalizedString("Catalog Visibility", comment: "Catalog Visibility label in Product Settings")
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

        let reuseIdentifier: String = SettingTitleAndValueTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [SettingTitleAndValueTableViewCell.self]
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

            let title = NSLocalizedString("Virtual Product", comment: "Virtual Product label in Product Settings")

            cell.title = title
            cell.isOn = settings.virtual
            cell.onChange = { newValue in
                // TODO-2509 Edit Product M3 analytics
                self.settings.virtual = newValue
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

            let title = NSLocalizedString("Enable Reviews", comment: "Enable Reviews label in Product Settings")

            cell.title = title
            cell.isOn = settings.reviewsAllowed
            cell.onChange = { newValue in
                // TODO-2509 Edit Product M3 analytics
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
            guard let cell = cell as? SettingTitleAndValueTableViewCell else {
                return
            }

            let title = NSLocalizedString("Slug", comment: "Slug label in Product Settings")
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

        let reuseIdentifier: String = SettingTitleAndValueTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [SettingTitleAndValueTableViewCell.self]
    }

    struct PurchaseNote: ProductSettingsRowMediator {
        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? SettingTitleAndValueTableViewCell else {
                return
            }

            let title = NSLocalizedString("Purchase Note", comment: "Purchase note label in Product Settings")
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

        let reuseIdentifier: String = SettingTitleAndValueTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [SettingTitleAndValueTableViewCell.self]
    }

    struct MenuOrder: ProductSettingsRowMediator {
        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? SettingTitleAndValueTableViewCell else {
                return
            }

            let title = NSLocalizedString("Menu Order", comment: "Menu order label in Product Settings")
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

        let reuseIdentifier: String = SettingTitleAndValueTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [SettingTitleAndValueTableViewCell.self]
    }
}
