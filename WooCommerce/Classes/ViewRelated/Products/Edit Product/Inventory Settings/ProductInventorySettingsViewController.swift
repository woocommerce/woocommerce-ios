import Combine
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

    private var skuBarcodeScannerCoordinator: ProductSKUBarcodeScannerCoordinator?

    private var sectionsSubscription: AnyCancellable?

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
        tableView.cellLayoutMarginsFollowReadableWidth = true

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
            tableView.registerNib(for: row.type)
        }
    }

    func registerTableViewHeaderFooters() {
        let headersAndFooters = [ ErrorSectionHeaderView.self ]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }

    func observeSections() {
        sectionsSubscription = viewModel.sections.sink { [weak self] sections in
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
        case let cell as TitleAndTextFieldTableViewCell where row == .globalUniqueIdentifier:
            configureGlobalUniqueIdentifier(cell: cell)
        case let cell as SwitchTableViewCell where row == .manageStock:
            configureManageStock(cell: cell)
        case let cell as SwitchTableViewCell where row == .limitOnePerOrder:
            configureLimitOnePerOrder(cell: cell)
        case let cell as UnitInputTableViewCell where row == .stockQuantity:
            configureStockQuantity(cell: cell)
        case let cell as TitleAndValueTableViewCell where row == .backorders:
            configureBackordersSetting(cell: cell)
        case let cell as TitleAndValueTableViewCell where row == .stockStatus:
            configureStockStatus(cell: cell)
        default:
            fatalError()
        }
    }

    func configureSKU(cell: TitleAndTextFieldTableViewCell) {
        var cellViewModel = Product.createSKUViewModel(sku: viewModel.sku) { [weak self] value in
            self?.viewModel.handleSKUChange(value) { [weak self] (isValid, shouldBringUpKeyboard) in
                self?.handleSKUValidation(isValid: isValid, shouldBringUpKeyboard: shouldBringUpKeyboard)
            }
        }
        switch viewModel.error {
        case .duplicatedSKU, .invalidSKU:
            cellViewModel = cellViewModel.stateUpdated(state: .error)
        default:
            break
        }
        cell.configure(viewModel: cellViewModel)

        // Configures accessory view for adding SKU from barcode scanner if camera is available.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return
        }

        let button = UIButton(type: .detailDisclosure)
        button.applyIconButtonStyle(icon: .scanImage)
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.scanSKUButtonTapped()
        }), for: .touchUpInside)
        button.accessibilityLabel = NSLocalizedString("Scan products", comment: "Scan Products")
        button.accessibilityHint = NSLocalizedString(
            "Scans barcodes that are associated with a product SKU for stock management.",
            comment: "VoiceOver accessibility hint, informing the user the button can be used to scan products."
        )
        cell.accessoryView = button
    }

    func configureGlobalUniqueIdentifier(cell: TitleAndTextFieldTableViewCell) {
        let cellViewModel = Product.createGlobalUniqueIdentifierViewModel() { _ in
        }

        cell.configure(viewModel: cellViewModel)

        /// Global Unique Identifiers are usually long, let's make a bit more of room to display it at once without truncating it
        cell.setSpacingBetweenTitleAndTextField(20)

        // Configures accessory view for adding SKU from barcode scanner if camera is available.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return
        }

        let button = UIButton(type: .detailDisclosure)
        button.applyIconButtonStyle(icon: .scanImage)
        button.accessibilityLabel = NSLocalizedString("Scan products", comment: "Scan Products")
        button.accessibilityHint = NSLocalizedString("productInventorySettings.GlobalUniqueIdentifier.ScanButton",
                                                     value: "Scans barcodes that are associated with a product Global Unique Identifier for stock management.",
                                                     comment: "VoiceOver accessibility hint, informing the user the button can be used to scan products.")
        cell.accessoryView = button
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

    func configureBackordersSetting(cell: TitleAndValueTableViewCell) {
        let title = NSLocalizedString("Backorders", comment: "Title of the cell in Product Inventory Settings > Backorders")
        cell.updateUI(title: title, value: viewModel.backordersSetting?.description)
        cell.accessoryType = .disclosureIndicator
    }

    // Manage stock disabled.

    func configureStockStatus(cell: TitleAndValueTableViewCell) {
        let title = NSLocalizedString("Stock status", comment: "Title of the cell in Product Inventory Settings > Stock status")
        cell.updateUI(title: title, value: viewModel.stockStatus?.description)
        cell.accessoryType = .disclosureIndicator
    }
}

// MARK: - SKU Scanner
//
private extension ProductInventorySettingsViewController {
    func scanSKUButtonTapped() {
        guard let navigationController = navigationController else {
            return
        }

        ServiceLocator.analytics.track(.productInventorySettingsSKUScannerButtonTapped)

        let coordinator = ProductSKUBarcodeScannerCoordinator(sourceNavigationController: navigationController) { [weak self] barcode in
            ServiceLocator.analytics.track(.productInventorySettingsSKUScanned)
            self?.onSKUBarcodeScanned(barcode: barcode.payloadStringValue)
        }
        view.endEditing(true)
        skuBarcodeScannerCoordinator = coordinator
        coordinator.start()
    }

    func onSKUBarcodeScanned(barcode: String) {
        viewModel.handleSKUFromBarcodeScanner(barcode) { [weak self] (isValid, shouldBringUpKeyboard) in
            self?.handleSKUValidation(isValid: isValid, shouldBringUpKeyboard: shouldBringUpKeyboard)
        }
    }
}

private extension ProductInventorySettingsViewController {
    func handleSKUValidation(isValid: Bool, shouldBringUpKeyboard: Bool) {
        enableDoneButton(isValid)
        if shouldBringUpKeyboard {
            getSkuCell()?.textFieldBecomeFirstResponder()
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
        case globalUniqueIdentifier
        case manageStock
        case limitOnePerOrder
        // Manage stock is enabled.
        case stockQuantity
        case backorders
        // Manage stock is disabled.
        case stockStatus

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .sku, .globalUniqueIdentifier:
                return TitleAndTextFieldTableViewCell.self
            case .manageStock, .limitOnePerOrder:
                return SwitchTableViewCell.self
            case .stockQuantity:
                return UnitInputTableViewCell.self
            case .stockStatus, .backorders:
                return TitleAndValueTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
