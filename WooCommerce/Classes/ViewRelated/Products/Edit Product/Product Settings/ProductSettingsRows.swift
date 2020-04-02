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

    struct CatalogVisibility: ProductSettingsRowMediator {

        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? BasicTableViewCell else {
                return
            }

            cell.textLabel?.text = NSLocalizedString("Catalog Visibility", comment: "Catalog Visibility label in Product Settings")
            cell.detailTextLabel?.text = "TO BE IMPLEMENTED"
            cell.accessoryType = .disclosureIndicator
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
            let viewController = ProductCatalogVisibilityViewController(settings: settings) { (productSettings) in
                self.settings.featured = productSettings.featured
                self.settings.catalogVisibility = productSettings.catalogVisibility
            }
            sourceViewController.navigationController?.pushViewController(viewController, animated: true)
        }

        let reuseIdentifier: String = BasicTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [BasicTableViewCell.self]
    }

    struct Status: ProductSettingsRowMediator {
        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? SettingTitleAndValueTableViewCell else {
                return
            }

            cell.updateUI(title: NSLocalizedString("Status", comment: "Status label in Product Settings"), value: settings.status.description)
            cell.accessoryType = .disclosureIndicator
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
            let title = NSLocalizedString("Status", comment: "Product status setting list selector navigation title")
            let viewProperties = ListSelectorViewProperties(navigationBarTitle: title)
            let dataSource = ProductStatusSettingListSelectorDataSource(selected: settings.status)

            let listSelectorViewController = ListSelectorViewController(viewProperties: viewProperties,
                                                                        dataSource: dataSource) { selected in

                                                                            self.settings.status = selected ?? self.settings.status
                                                                            onCompletion(self.settings)
            }
            sourceViewController.navigationController?.pushViewController(listSelectorViewController, animated: true)

        }

        let reuseIdentifier: String = SettingTitleAndValueTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [SettingTitleAndValueTableViewCell.self]
    }

    struct Slug: ProductSettingsRowMediator {
        private let settings: ProductSettings

        init(_ settings: ProductSettings) {
            self.settings = settings
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? BasicTableViewCell else {
                return
            }

            cell.textLabel?.text = NSLocalizedString("Slug", comment: "Slug label in Product Settings")
            cell.detailTextLabel?.text = "TO BE IMPLEMENTED"
            cell.accessoryType = .disclosureIndicator
        }

        func handleTap(sourceViewController: UIViewController, onCompletion: @escaping (ProductSettings) -> Void) {
            // TODO: Show a VC
        }

        let reuseIdentifier: String = BasicTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [BasicTableViewCell.self]
    }
}
