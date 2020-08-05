import UIKit
import Yosemite

final class ProductInventorySettingsViewController: UIViewController {

    /// The type of form with different inventory settings.
    enum FormType {
        /// Allows editing all inventory settings.
        case inventory
        /// Only SKU is editable.
        case sku
    }

    private let viewModel: ProductInventorySettingsViewModelOutput & ProductInventorySettingsActionHandler
    private var sections: [Section] = []

    @IBOutlet private weak var tableView: UITableView!

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        let keyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
            self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
        }
        return keyboardFrameObserver
    }()

    typealias Completion = (_ data: ProductInventoryEditableData) -> Void
    private let onCompletion: Completion

    private var cancellable: ObservationToken?

    init(product: ProductFormDataModel, formType: FormType = .inventory, completion: @escaping Completion) {
        self.viewModel = ProductInventorySettingsViewModel(formType: formType, productModel: product)
        self.onCompletion = completion
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
        observeSections()
        handleSwipeBackGesture()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if viewModel.formType == .sku {
            configureSKUFormTextFieldAsFirstResponder()
        }
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

// MARK: - View Configuration
//
private extension ProductInventorySettingsViewController {

    func configureNavigationBar() {
        switch viewModel.formType {
        case .inventory:
            title = NSLocalizedString("Inventory", comment: "Product Inventory Settings navigation title")
        case .sku:
            title = NSLocalizedString("SKU", comment: "Edit Product SKU navigation title")
        }

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

    /// Since there is only a text field in this view for Product SKU form, the text field becomes the first responder immediately when the view did appear
    ///
    func configureSKUFormTextFieldAsFirstResponder() {
        if let indexPath = sections.indexPathForRow(.sku) {
            let cell = tableView.cellForRow(at: indexPath) as? TitleAndTextFieldTableViewCell
            cell?.textFieldBecomeFirstResponder()
        }
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

    func observeSections() {
        // Until we have a passthrough/behavior subject, we have to configure the initial value manually.
        sections = viewModel.sectionsValue
        tableView.reloadData()

        cancellable = viewModel.sections.subscribe { [weak self] sections in
            self?.sections = sections
            self?.tableView.reloadData()
        }
    }
}

// MARK: - Navigation actions handling
//
extension ProductInventorySettingsViewController {

    override func shouldPopOnBackButton() -> Bool {
        guard viewModel.hasUnsavedChanges() else {
            return true
        }
        presentBackNavigationActionSheet()
        return false
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    @objc private func completeUpdating() {
        viewModel.completeUpdating(onCompletion: onCompletion)
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
            let command = ProductStockStatusListSelectorCommand(selected: viewModel.stockStatus)
            let listSelectorViewController = ListSelectorViewController(command: command) { [weak self] selected in
                self?.viewModel.handleStockStatusChange(selected)
            }
            navigationController?.pushViewController(listSelectorViewController, animated: true)
        case .backorders:
            let command = ProductBackordersSettingListSelectorCommand(selected: viewModel.backordersSetting)
            let listSelectorViewController = ListSelectorViewController(command: command) { [weak self] selected in
                self?.viewModel.handleBackordersSettingChange(selected)
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
        var cellViewModel = Product.createSKUViewModel(sku: viewModel.sku) { [weak self] value in
            self?.viewModel.handleSKUChange(value) { [weak self] (isValid, shouldBringUpKeyboard) in
                self?.enableDoneButton(isValid)
                if shouldBringUpKeyboard {
                    self?.getSkuCell()?.textFieldBecomeFirstResponder()
                }
            }
        }
        switch viewModel.error {
        case .duplicatedSKU, .invalidSKU:
            cellViewModel = cellViewModel.stateUpdated(state: .error)
        default:
            break
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureManageStock(cell: SwitchTableViewCell) {
        cell.title = NSLocalizedString("Manage stock", comment: "Title of the cell in Product Inventory Settings > Manage stock")
        cell.isOn = viewModel.manageStockEnabled
        cell.onChange = { [weak self] value in
            self?.viewModel.handleManageStockEnabledChange(value)
        }
    }

    func configureLimitOnePerOrder(cell: SwitchTableViewCell) {
        cell.title = NSLocalizedString("Limit one per order", comment: "Title of the cell in Product Inventory Settings > Limit one per order")
        cell.isOn = viewModel.soldIndividually == true
        cell.onChange = { [weak self] value in
            self?.viewModel.handleSoldIndividuallyChange(value)
        }
    }

    // Manage stock enabled.

    func configureStockQuantity(cell: UnitInputTableViewCell) {
        let cellViewModel = Product.createStockQuantityViewModel(stockQuantity: viewModel.stockQuantity) { [weak self] value in
            self?.viewModel.handleStockQuantityChange(value)
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureBackordersSetting(cell: SettingTitleAndValueTableViewCell) {
        let title = NSLocalizedString("Backorders", comment: "Title of the cell in Product Inventory Settings > Backorders")
        cell.updateUI(title: title, value: viewModel.backordersSetting?.description)
        cell.accessoryType = .disclosureIndicator
    }

    // Manage stock disabled.

    func configureStockStatus(cell: SettingTitleAndValueTableViewCell) {
        let title = NSLocalizedString("Stock status", comment: "Title of the cell in Product Inventory Settings > Stock status")
        cell.updateUI(title: title, value: viewModel.stockStatus?.description)

        // Stock status is only editable for `Product`.
        if viewModel.isStockStatusEnabled {
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.accessoryType = .none
            cell.selectionStyle = .none
        }
    }
}

// MARK: - Convenience Methods
//
private extension ProductInventorySettingsViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    func getSkuCell() -> TitleAndTextFieldTableViewCell? {
        guard let indexPath = sections.indexPathForRow(.sku) else {
            return nil
        }
        return tableView.cellForRow(at: indexPath) as? TitleAndTextFieldTableViewCell
    }
}

private extension ProductInventorySettingsViewController {
    enum Constants {
        static let estimatedSectionHeaderHeight: CGFloat = 44
    }
}

extension ProductInventorySettingsViewController {
    struct Section: RowIterable, Equatable {
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

        fileprivate var type: UITableViewCell.Type {
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

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
