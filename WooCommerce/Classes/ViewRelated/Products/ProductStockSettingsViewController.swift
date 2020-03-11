import UIKit
import Yosemite

final class ProductStockSettingsViewController: UIViewController {

    struct ProductStockEditableData {
        let manageStock: Bool
        let stockQuantity: Int?
        let backordersSetting: ProductBackordersSetting?
        let stockStatus: ProductStockStatus?
    }

    @IBOutlet private weak var tableView: UITableView!

    private let product: Product

    // Editable data - shared.
    //
    private var manageStockEnabled: Bool

    // Editable data - manage stock enabled.
    private var stockQuantity: Int?
    private var backordersSetting: ProductBackordersSetting?

    // Editable data - manage stock disabled.
    private var stockStatus: ProductStockStatus?

    /// Table Sections to be rendered
    ///
    private var sections: [Section] = []

    typealias Completion = (_ data: ProductStockEditableData) -> Void
    private let onCompletion: Completion

    init(product: Product, stockQuantity: Int?, completion: @escaping Completion) {
        self.onCompletion = completion

        self.product = product

        self.manageStockEnabled = product.manageStock

        self.stockQuantity = stockQuantity ?? product.stockQuantity
        self.backordersSetting = product.backordersSetting
        self.stockStatus = product.productStockStatus

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
        reloadSections()
    }
}

// MARK: - View Updates
//
private extension ProductStockSettingsViewController {
    func reloadSections() {
        let stockSection: Section
        if manageStockEnabled {
            stockSection = Section(rows: [.manageStock, .stockQuantity, .backorders])
        } else {
            stockSection = Section(rows: [.manageStock, .stockStatus])
        }

        sections = [
            stockSection
        ]

        tableView.reloadData()
    }
}

// MARK: - View Configuration
//
private extension ProductStockSettingsViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Inventory", comment: "Product Inventory Settings navigation title")

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(completeUpdating))
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        registerTableViewCells()
        registerTableViewHeaderFooters()

        tableView.tableFooterView = UIView()

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }

    func registerTableViewHeaderFooters() {
        let headersAndFooters = [ ErrorSectionHeaderView.self ]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }
}

// MARK: - Navigation actions handling
//
extension ProductStockSettingsViewController {

    override func shouldPopOnBackButton() -> Bool {
        if manageStockEnabled != product.manageStock ||
            stockQuantity != product.stockQuantity || backordersSetting != product.backordersSetting || stockStatus != product.productStockStatus {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    @objc private func completeUpdating() {
        let data = ProductStockEditableData(manageStock: self.manageStockEnabled,
                                            stockQuantity: self.stockQuantity,
                                            backordersSetting: self.backordersSetting,
                                            stockStatus: self.stockStatus)
        self.onCompletion(data)
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductStockSettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension ProductStockSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rowAtIndexPath(indexPath) {
        case .stockStatus:
            let title = NSLocalizedString("Stock status", comment: "Product stock status list selector navigation title")
            let viewProperties = ListSelectorViewProperties(navigationBarTitle: title)
            let dataSource = ProductStockStatusListSelectorDataSource(selected: stockStatus)
            let listSelectorViewController = ListSelectorViewController(viewProperties: viewProperties,
                                                                        dataSource: dataSource) { [weak self] selected in
                                                                            self?.stockStatus = selected
                                                                            self?.tableView.reloadData()
            }
            navigationController?.pushViewController(listSelectorViewController, animated: true)
        case .backorders:
            let title = NSLocalizedString("Backorders", comment: "Product backorders setting list selector navigation title")
            let viewProperties = ListSelectorViewProperties(navigationBarTitle: title)
            let dataSource = ProductBackordersSettingListSelectorDataSource(selected: backordersSetting)
            let listSelectorViewController = ListSelectorViewController(viewProperties: viewProperties,
                                                                        dataSource: dataSource) { [weak self] selected in
                                                                            self?.backordersSetting = selected
                                                                            self?.tableView.reloadData()
            }
            navigationController?.pushViewController(listSelectorViewController, animated: true)
        default:
            return
        }
    }
}

// MARK: - Cell configuration
//
private extension ProductStockSettingsViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as SwitchTableViewCell where row == .manageStock:
            configureManageStock(cell: cell)
        case let cell as UnitInputTableViewCell where row == .stockQuantity:
            configureStockQuantity(cell: cell)
        case let cell as SettingTitleAndValueTableViewCell where row == .backorders:
            configureBackordersSetting(cell: cell)
        case let cell as SettingTitleAndValueTableViewCell where row == .stockStatus:
            configureStockStatus(cell: cell)
        default:
            fatalError()
        }
    }

    func configureManageStock(cell: SwitchTableViewCell) {
        cell.title = NSLocalizedString("Manage stock", comment: "Title of the cell in Product Inventory Settings > Manage stock")
        cell.isOn = manageStockEnabled
        cell.onChange = { [weak self] value in
            self?.manageStockEnabled = value
            self?.reloadSections()
        }
    }

    // Manage stock enabled.

    func configureStockQuantity(cell: UnitInputTableViewCell) {
        let viewModel = Product.createDiffableStockQuantityViewModel(originalStockQuantity: product.stockQuantity, stockQuantity: stockQuantity) { [weak self] value in
            self?.handleStockQuantityChange(value)
        }
        cell.configure(viewModel: viewModel)
    }

    func configureBackordersSetting(cell: SettingTitleAndValueTableViewCell) {
        let title = NSLocalizedString("Backorders", comment: "Title of the cell in Product Inventory Settings > Backorders")
        cell.updateUI(title: title, value: backordersSetting?.description)
        cell.accessoryType = .disclosureIndicator
    }

    // Manage stock disabled.

    func configureStockStatus(cell: SettingTitleAndValueTableViewCell) {
        let title = NSLocalizedString("Stock status", comment: "Title of the cell in Product Inventory Settings > Stock status")
        cell.updateUI(title: title, value: stockStatus?.description)
        cell.accessoryType = .disclosureIndicator
    }
}

// MARK: - Convenience Methods
//
private extension ProductStockSettingsViewController {
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    func handleStockQuantityChange(_ stockQuantity: String?) {
        guard let stockQuantity = stockQuantity else {
            return
        }
        self.stockQuantity = Int(stockQuantity)
    }
}

private extension ProductStockSettingsViewController {

    enum Constants {
        static let estimatedSectionHeaderHeight: CGFloat = 44
    }

    struct Section {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case manageStock
        // Manage stock is enabled.
        case stockQuantity
        case backorders
        // Manage stock is disabled.
        case stockStatus

        var type: UITableViewCell.Type {
            switch self {
            case .manageStock:
                return SwitchTableViewCell.self
            case .stockQuantity:
                return UnitInputTableViewCell.self
            case .stockStatus, .backorders:
                return SettingTitleAndValueTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
