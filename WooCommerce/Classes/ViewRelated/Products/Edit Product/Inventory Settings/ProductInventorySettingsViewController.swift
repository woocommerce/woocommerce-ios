import UIKit
import Yosemite

final class ProductInventorySettingsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    // Editable data - shared.
    //
    private var sku: String?
    private var manageStockEnabled: Bool
    private var soldIndividually: Bool

    // Editable data - manage stock enabled.
    private var stockQuantity: Int?
    private var backordersSetting: ProductBackordersSetting?

    // Editable data - manage stock disabled.
    private var stockStatus: ProductStockStatus?

    /// Table Sections to be rendered
    ///
    private var sections: [Section] = []

    init(product: Product) {
        self.sku = product.sku
        self.manageStockEnabled = product.manageStock
        self.soldIndividually = product.soldIndividually

        if manageStockEnabled {
            self.stockQuantity = product.stockQuantity
            self.backordersSetting = product.backordersSetting
        } else {
            self.stockStatus = product.productStockStatus
        }

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
private extension ProductInventorySettingsViewController {
    func reloadSections() {
        let stockSection: Section
        if manageStockEnabled {
            stockSection = Section(rows: [.manageStock, .stockQuantity, .backorders])
        } else {
            stockSection = Section(rows: [.manageStock, .stockStatus])
        }

        sections = [
            Section(rows: [.sku]),
            stockSection,
            Section(rows: [.limitOnePerOrder])
        ]

        tableView.reloadData()
    }
}

// MARK: - View Configuration
//
private extension ProductInventorySettingsViewController {

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

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }
}

// MARK: - Navigation actions handling
//
private extension ProductInventorySettingsViewController {
    @objc func completeUpdating() {
        // TODO-1424: update shipping settings
    }
}

// MARK: - Input changes handling
//
private extension ProductInventorySettingsViewController {
    func handleSKUChange(sku: String?) {
        self.sku = sku
    }

    func handleStockQuantityChange(stockQuantity: String?) {
        guard let stockQuantity = stockQuantity else {
            return
        }
        self.stockQuantity = Int(stockQuantity)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductInventorySettingsViewController: UITableViewDataSource {

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
extension ProductInventorySettingsViewController: UITableViewDelegate {
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
            let title = NSLocalizedString("Allow backorders?", comment: "Product backorders setting list selector navigation title")
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
private extension ProductInventorySettingsViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as UnitInputTableViewCell where row == .sku:
            configureSKU(cell: cell)
        case let cell as SwitchTableViewCell where row == .manageStock:
            configureManageStock(cell: cell)
        case let cell as SwitchTableViewCell where row == .limitOnePerOrder:
            configureLimitOnePerOrder(cell: cell)
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

    func configureSKU(cell: UnitInputTableViewCell) {
        let viewModel = Product.createSKUViewModel(sku: sku) { [weak self] value in
            self?.handleSKUChange(sku: value)
        }
        cell.configure(viewModel: viewModel)
    }

    func configureManageStock(cell: SwitchTableViewCell) {
        cell.title = NSLocalizedString("Manage stock", comment: "Title of the cell in Product Inventory Settings > Manage stock")
        cell.isOn = manageStockEnabled
        cell.onChange = { [weak self] value in
            self?.manageStockEnabled = value
            self?.reloadSections()
        }
    }

    func configureLimitOnePerOrder(cell: SwitchTableViewCell) {
        cell.title = NSLocalizedString("Limit one per order", comment: "Title of the cell in Product Inventory Settings > Limit one per order")
        cell.isOn = soldIndividually
        cell.onChange = { [weak self] value in
            self?.soldIndividually = value
        }
    }

    // Manage stock enabled.

    func configureStockQuantity(cell: UnitInputTableViewCell) {
        let viewModel = Product.createStockQuantityViewModel(stockQuantity: stockQuantity) { [weak self] value in
            self?.handleStockQuantityChange(stockQuantity: value)
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
private extension ProductInventorySettingsViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}

private extension ProductInventorySettingsViewController {

    struct Section {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case sku
        case manageStock
        case limitOnePerOrder
        // Manage stock is enabled.
        case stockQuantity
        case backorders
        // Manage stock is disabled.
        case stockStatus

        var type: UITableViewCell.Type {
            switch self {
            case .sku:
                // TODO-1424: update with a input cell without a unit
                return UnitInputTableViewCell.self
            case .manageStock, .limitOnePerOrder:
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
