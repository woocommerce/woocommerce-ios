import UIKit
import Yosemite

final class ProductCatalogVisibilityViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    // Completion callback
    //
    typealias Completion = (_ productSettings: ProductSettings) -> Void
    private let onCompletion: Completion
    
    private var productSettings: ProductSettings
    
    private let sections: [Section]
    
    /// Init
    ///
    init(settings: ProductSettings, completion: @escaping Completion) {
        productSettings = settings
        sections = [Section(rows: [.featuredProduct]), Section(rows: [.visible, .catalog, .search, .hidden])]
        onCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureMainView()
        configureTableView()
    }
    
}


// MARK: - View Configuration
//
private extension ProductCatalogVisibilityViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Catalog Visibility", comment: "Product Catalog Visibility navigation title")

        removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.register(SwitchTableViewCell.loadNib(), forCellReuseIdentifier: SwitchTableViewCell.reuseIdentifier)
        tableView.register(BasicTableViewCell.loadNib(), forCellReuseIdentifier: BasicTableViewCell.reuseIdentifier)
        tableView.register(TwoColumnSectionHeaderView.loadNib(), forHeaderFooterViewReuseIdentifier: TwoColumnSectionHeaderView.reuseIdentifier)
        
        tableView.dataSource = self
        tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()
    }
}

// MARK: - Navigation actions handling
//
extension ProductCatalogVisibilityViewController {

    override func shouldPopOnBackButton() -> Bool {
//        if viewModel.hasUnsavedChanges() {
//            presentBackNavigationActionSheet()
//            return false
//        }
        return true
    }

    @objc private func completeUpdating() {
        //onCompletion(nil)
        navigationController?.popViewController(animated: true)
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductCatalogVisibilityViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension ProductCatalogVisibilityViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        if let catalogVisibility = row.catalogVisibility {
            productSettings.catalogVisibility = catalogVisibility
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let headerID = TwoColumnSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? TwoColumnSectionHeaderView else {
            assertionFailure("Unregistered \(TwoColumnSectionHeaderView.self) in UITableView")
            return nil
        }

        headerView.leftText = nil
        headerView.rightText = nil

        return headerView
    }
}

// MARK: - Support for UITableViewDataSource
//
private extension ProductCatalogVisibilityViewController {
    /// Configure cellForRowAtIndexPath:
    ///
   func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as SwitchTableViewCell:
            configureFeaturedProduct(cell: cell)
        case let cell as BasicTableViewCell:
            configureCatalogVisibilitySelector(cell: cell, indexPath: indexPath)
        default:
            fatalError("Unidentified product catalog visibility row type")
        }
    }
    
    func configureFeaturedProduct(cell: SwitchTableViewCell) {
        cell.title = NSLocalizedString("Featured Product", comment: "Featured Product switch in Product Catalog Visibility")
        cell.isOn = productSettings.featured
        cell.onChange = { [weak self] value in
            self?.productSettings.featured = value
        }
    }
    
    func configureCatalogVisibilitySelector(cell: BasicTableViewCell, indexPath: IndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]
        cell.selectionStyle = .default
        cell.textLabel?.text = row.catalogVisibility?.description
        cell.accessoryType = productSettings.catalogVisibility == row.catalogVisibility ? .checkmark : .none
    }
}

// MARK: - Constants
//
extension ProductCatalogVisibilityViewController {
    
    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case featuredProduct
        case visible
        case catalog
        case search
        case hidden
        
        var reuseIdentifier: String {
            switch self {
            case .featuredProduct:
                return SwitchTableViewCell.reuseIdentifier
            case .visible, .catalog, .search, .hidden:
                return BasicTableViewCell.reuseIdentifier
            }
        }
        
        var catalogVisibility: ProductCatalogVisibility? {
            switch self {
            case .visible:
                return .visible
            case .catalog:
                return .catalog
            case .search:
                return .search
            case .hidden:
                return .hidden
            default:
                return nil
            }
        }
    }
    
    /// Table Sections
    ///
    struct Section {
        let title: String?
        let footer: String?
        let rows: [Row]
        
        init(title: String? = nil, footer: String? = nil, rows: [Row]) {
            self.title = title
            self.footer = footer
            self.rows = rows
        }
        
        init(title: String? = nil, rightTitle: String? = nil, footer: String? = nil, row: Row) {
            self.init(title: title, footer: footer, rows: [row])
        }
    }
}
