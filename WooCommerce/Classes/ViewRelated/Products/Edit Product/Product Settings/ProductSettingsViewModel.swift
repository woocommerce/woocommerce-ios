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


// MARK: - Sections and Rows declaration
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
