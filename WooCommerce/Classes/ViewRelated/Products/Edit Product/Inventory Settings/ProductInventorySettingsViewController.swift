import UIKit
import Yosemite

final class ProductInventorySettingsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let product: Product

    private let siteID: Int64

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

    private var error: ProductUpdateError?

    // Sku validation
    private var skuIsValid: Bool = true

    private lazy var throttler: Throttler = Throttler(seconds: 0.5)

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        let keyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
            self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
        }
        return keyboardFrameObserver
    }()

    typealias Completion = (_ data: ProductInventoryEditableData) -> Void
    private let onCompletion: Completion

    init(product: Product, completion: @escaping Completion) {
        self.onCompletion = completion

        self.product = product

        self.siteID = product.siteID

        self.sku = product.sku
        self.manageStockEnabled = product.manageStock
        self.soldIndividually = product.soldIndividually

        self.stockQuantity = product.stockQuantity
        self.backordersSetting = product.backordersSetting
        self.stockStatus = product.productStockStatus

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        startListeningToNotifications()
        configureNavigationBar()
        configureMainView()
        configureTableView()
        reloadSections()
        handleSwipeBackGesture()
    }
}

// MARK: - Keyboard management
//
extension ProductInventorySettingsViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
    }
}

private extension ProductInventorySettingsViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
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

        let skuSection: Section
        if let error = error {
            skuSection = Section(errorTitle: error.alertMessage,
                                 rows: [.sku])
        } else {
            skuSection = Section(rows: [.sku])
        }

        sections = [
            skuSection,
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
        registerTableViewHeaderFooters()

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
extension ProductInventorySettingsViewController {

    override func shouldPopOnBackButton() -> Bool {
        guard skuIsValid else {
            return true
        }

        // Checks general settings regardless of whether stock management is enabled.
        let hasChangesInGeneralSettings = sku != product.sku || manageStockEnabled != product.manageStock || soldIndividually != product.soldIndividually

        if hasChangesInGeneralSettings {
            presentBackNavigationActionSheet()
            return false
        }

        // Checks stock settings depending on whether stock management is enabled.
        let hasChangesInStockSettings: Bool
        if manageStockEnabled {
            hasChangesInStockSettings = stockQuantity != product.stockQuantity || backordersSetting != product.backordersSetting
        } else {
            hasChangesInStockSettings = stockStatus != product.productStockStatus
        }

        if hasChangesInStockSettings {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    @objc private func completeUpdating() {
        if skuIsValid {
            let data = ProductInventoryEditableData(sku: self.sku,
                                            manageStock: self.manageStockEnabled,
                                            soldIndividually: self.soldIndividually,
                                            stockQuantity: self.stockQuantity,
                                            backordersSetting: self.backordersSetting,
                                            stockStatus: self.stockStatus)
            self.onCompletion(data)
        }
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }

    private func enableDoneButton(_ enabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }
}

// MARK: - Input changes handling
//
private extension ProductInventorySettingsViewController {
    func handleSKUChange(_ sku: String?) {
        self.sku = sku

        // If the sku is identical to the old one, is always valid
        guard sku != product.sku else {
            skuIsValid = true
            hideError()
            throttler.cancel()
            getSkuCell()?.textFieldBecomeFirstResponder()
            enableDoneButton(true)
            return
        }

        // Throttled API call
        let siteID = self.siteID
        throttler.throttle {
            DispatchQueue.main.async {
                let action = ProductAction.validateProductSKU(sku, siteID: siteID) { [weak self] isValid in
                    guard let self = self else {
                        return
                    }
                    self.skuIsValid = isValid

                    guard isValid else {
                        self.displayError(error: .duplicatedSKU)
                        self.getSkuCell()?.textFieldBecomeFirstResponder()
                        self.enableDoneButton(false)
                        return
                    }
                    self.hideError()
                    self.enableDoneButton(true)
                }

                ServiceLocator.stores.dispatch(action)
            }
        }
    }

    func handleStockQuantityChange(_ stockQuantity: String?) {
        guard let stockQuantity = stockQuantity else {
            return
        }
        self.stockQuantity = Int(stockQuantity)
    }
}

// MARK: - Error handling
//
private extension ProductInventorySettingsViewController {
    func displayError(error: ProductUpdateError) {
        self.error = error
        reloadSections()
    }

    func hideError() {
        // This check is useful so we don't reload while typing each letter in the sections
        if error != nil {
            error = nil
            reloadSections()
        }
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

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = sections[section]
        guard let errorTitle = section.errorTitle else {
            return nil
        }

        let headerID = ErrorSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? ErrorSectionHeaderView else {
            fatalError()
        }
        headerView.configure(title: errorTitle)
        UIAccessibility.post(notification: .layoutChanged, argument: headerView)
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = sections[section]
        guard let errorTitle = section.errorTitle, errorTitle.isEmpty == false else {
            return 0
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        let section = sections[section]
        guard let errorTitle = section.errorTitle, errorTitle.isEmpty == false else {
            return 0
        }
        return Constants.estimatedSectionHeaderHeight
    }
}

// MARK: - Cell configuration
//
private extension ProductInventorySettingsViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TitleAndTextFieldTableViewCell where row == .sku:
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

    func configureSKU(cell: TitleAndTextFieldTableViewCell) {
        var viewModel = Product.createSKUViewModel(sku: sku) { [weak self] value in
            self?.handleSKUChange(value)
        }
        switch error {
        case .duplicatedSKU, .invalidSKU:
            viewModel = viewModel.stateUpdated(state: .error)
        default:
            break
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
private extension ProductInventorySettingsViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    func getIndexPathForRow(_ row: Row) -> IndexPath? {
        for s in 0 ..< sections.count {
            for r in 0 ..< sections[s].rows.count {
                if sections[s].rows[r] == row {
                    return IndexPath(row: r, section: s)
                }
            }
        }
        return nil
    }

    func getSkuCell() -> TitleAndTextFieldTableViewCell? {
        guard let indexPath = getIndexPathForRow(.sku) else {
            return nil
        }
        return tableView.cellForRow(at: indexPath) as? TitleAndTextFieldTableViewCell
    }
}

private extension ProductInventorySettingsViewController {

    enum Constants {
        static let estimatedSectionHeaderHeight: CGFloat = 44
    }

    struct Section {
        let errorTitle: String?
        let rows: [Row]

        init(errorTitle: String? = nil,
             rows: [Row]) {
            self.errorTitle = errorTitle
            self.rows = rows
        }
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
                return TitleAndTextFieldTableViewCell.self
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
