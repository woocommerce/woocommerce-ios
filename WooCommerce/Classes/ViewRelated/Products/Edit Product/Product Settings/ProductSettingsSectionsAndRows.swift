import UIKit
import Yosemite

// MARK: - Mediators Protocols
//
/// Encapsulates configuration and interaction of a UITableView section header.
protocol ProductSettingsSectionMediator {
    var title: String { get }
    var rows: [ProductSettingsRowMediator] { get }

    init(_ product: Product)
}

/// Encapsulates configuration and interaction of a UITableView row.
protocol ProductSettingsRowMediator {

        /// Update the cell UI and bind to events if needed.
        func configure(cell: UITableViewCell)

        /// Show a reusable ViewController like AztecEditorViewController.
        ///
        func handleTap(sourceViewController: UIViewController)

        var reuseIdentifier: String { get }

        /// A table row could be presented by different `UITableViewCell` types, depending on the state.
        var cellTypes: [UITableViewCell.Type] { get }

        init(_ product: Product)
}


// MARK: - Sections and Rows declaration for Product Settings
//
enum ProductSettingsSections {
    /// Publish Settings section
    struct PublishSettings: ProductSettingsSectionMediator {
        let title = NSLocalizedString("Publish Settings", comment: "Title of the Publish Settings section on Product Settings screen")

        let rows: [ProductSettingsRowMediator]

        init(_ product: Product) {
            rows = [ProductSettingsRows.CatalogVisibility(product)]
        }
    }

    /// More Settings section
    struct MoreOptions: ProductSettingsSectionMediator {
        let title = NSLocalizedString("More Options", comment: "Title of the More Options section on Product Settings screen")

        let rows: [ProductSettingsRowMediator]

        init(_ product: Product) {
            rows = [ProductSettingsRows.Slug(product)]
        }
    }
}

enum ProductSettingsRows {

    struct CatalogVisibility: ProductSettingsRowMediator {
        private let product: Product

        init(_ product: Product) {
            self.product = product
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? BasicTableViewCell else {
                return
            }

            cell.textLabel?.text = NSLocalizedString("Catalog Visibility", comment: "Catalog Visibility label in Product Settings")
            cell.detailTextLabel?.text = product.catalogVisibilityKey
            cell.accessoryType = .disclosureIndicator
        }

        func handleTap(sourceViewController: UIViewController) {
            // TODO: Show a VC
        }

        let reuseIdentifier: String = BasicTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [BasicTableViewCell.self]
    }

    struct Slug: ProductSettingsRowMediator {
        private let product: Product

        init(_ product: Product) {
            self.product = product
        }

        func configure(cell: UITableViewCell) {
            guard let cell = cell as? BasicTableViewCell else {
                return
            }

            cell.textLabel?.text = NSLocalizedString("Slug", comment: "Slug label in Product Settings")
            cell.detailTextLabel?.text = product.slug
            cell.accessoryType = .disclosureIndicator
        }

        func handleTap(sourceViewController: UIViewController) {
            // TODO: Show a VC
        }

        let reuseIdentifier: String = BasicTableViewCell.reuseIdentifier

        let cellTypes: [UITableViewCell.Type] = [BasicTableViewCell.self]
    }
}
