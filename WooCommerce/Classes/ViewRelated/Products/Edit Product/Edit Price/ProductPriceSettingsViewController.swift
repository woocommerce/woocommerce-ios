import UIKit
import Yosemite

// MARK: - ProductPriceSettingsViewController
//
final class ProductPriceSettingsViewController: UIViewController {

    @IBOutlet weak private var tableView: UITableView!

    private let siteID: Int64

    private let viewModel: ProductPriceSettingsViewModelOutput & ProductPriceSettingsActionHandler

    // Timezone of the website
    //
    private let timezoneForScheduleSaleDates = TimeZone.siteTimezone

    // Date Pickers status
    //
    private var datePickerSaleFromVisible = false
    private var datePickerSaleToVisible = false

    /// Table Sections to be rendered
    ///
    private var sections: [Section] = []

    // Completion callback
    //
    typealias Completion = (_ regularPrice: String?,
        _ salePrice: String?,
        _ dateOnSaleStart: Date?,
        _ dateOnSaleEnd: Date?,
        _ taxStatus: ProductTaxStatus,
        _ taxClass: TaxClass?) -> Void
    private let onCompletion: Completion

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        let keyboardFrameObserver = KeyboardFrameObserver(onKeyboardFrameUpdate: handleKeyboardFrameUpdate(keyboardFrame:))
        return keyboardFrameObserver
    }()

    /// Init
    ///
    init(product: Product, completion: @escaping Completion) {
        siteID = product.siteID
        viewModel = ProductPriceSettingsViewModel(product: product)
        onCompletion = completion
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
        configureSections()
        configureTableView()
        retrieveProductTaxClass()
    }
}

// MARK: - Keyboard management
//
extension ProductPriceSettingsViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
    }
}

 private extension ProductPriceSettingsViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

// MARK: - View Configuration
//
private extension ProductPriceSettingsViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Price", comment: "Product Price Settings navigation title")

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(completeUpdating))
        removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        registerTableViewHeaderSections()
        registerTableViewCells()

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewHeaderSections() {
        let headerNib = UINib(nibName: TwoColumnSectionHeaderView.reuseIdentifier, bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: TwoColumnSectionHeaderView.reuseIdentifier)
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }

    func retrieveProductTaxClass() {
        viewModel.retrieveProductTaxClass { [weak self] in
            self?.refreshViewContent()
        }
    }
}

// MARK: - Navigation actions handling
//
extension ProductPriceSettingsViewController {

    override func shouldPopOnBackButton() -> Bool {
        if viewModel.hasUnsavedChanges() {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    @objc private func completeUpdating() {
        viewModel.completeUpdating(onCompletion: { [weak self] (regularPrice, salePrice, dateOnSaleStart, dateOnSaleEnd, taxStatus, taxClass) in
            self?.onCompletion(regularPrice, salePrice, dateOnSaleStart, dateOnSaleEnd, taxStatus, taxClass)
            }, onError: { [weak self] error in
                switch error {
                case .salePriceWithoutRegularPrice:
                    self?.displaySalePriceWithoutRegularPriceErrorNotice()
                case .salePriceHigherThanRegularPrice:
                    self?.displaySalePriceErrorNotice()
                }
        })
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - Error handling
//
private extension ProductPriceSettingsViewController {

    /// Displays a Notice onscreen, indicating that you can't add a sale price without adding before the regular price
    ///
    func displaySalePriceWithoutRegularPriceErrorNotice() {
        UIApplication.shared.keyWindow?.endEditing(true)
        let message = NSLocalizedString("The sale price can't be added without the regular price.",
                                        comment: "Product price error notice message, when the sale price is added but the regular price is not")

        let notice = Notice(title: message, feedbackType: .error)
        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Displays a Notice onscreen, indicating that the sale price need to be higher than the regular price
    ///
    func displaySalePriceErrorNotice() {
        UIApplication.shared.keyWindow?.endEditing(true)
        let message = NSLocalizedString("The sale price should be lower than the regular price.",
                                        comment: "Product price error notice message, when the sale price is higher than the regular price")

        let notice = Notice(title: message, feedbackType: .error)
        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductPriceSettingsViewController: UITableViewDataSource {

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
extension ProductPriceSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = rowAtIndexPath(indexPath)

        switch row {
        case .scheduleSaleFrom:
            datePickerSaleFromVisible = !datePickerSaleFromVisible
            refreshViewContent()
        case .scheduleSaleTo:
            datePickerSaleToVisible = !datePickerSaleToVisible
            refreshViewContent()
        case .removeSaleTo:
            datePickerSaleToVisible = false
            viewModel.handleSaleEndDateChange(nil)
            refreshViewContent()
        case .taxStatus:
            let title = NSLocalizedString("Tax Status", comment: "Navigation bar title of the Product tax status selector screen")
            let viewProperties = ListSelectorViewProperties(navigationBarTitle: title)
            let dataSource = ProductTaxStatusListSelectorDataSource(selected: viewModel.taxStatus)
            let listSelectorViewController = ListSelectorViewController(viewProperties: viewProperties,
                                                                        dataSource: dataSource) { [weak self] selected in
                                                                            if let selected = selected {
                                                                                self?.viewModel.handleTaxStatusChange(selected)
                                                                            }
                                                                            self?.refreshViewContent()
            }
            navigationController?.pushViewController(listSelectorViewController, animated: true)
        case .taxClass:
            let dataSource = ProductTaxClassListSelectorDataSource(siteID: siteID, selected: viewModel.taxClass)
            let navigationBarTitle = NSLocalizedString("Tax classes", comment: "Navigation bar title of the Product tax class selector screen")
            let noResultsPlaceholderText = NSLocalizedString("No tax classes yet",
            comment: "The text on the placeholder overlay when there are no tax classes on the Tax Class list picker")
            let noResultsPlaceholderImage = UIImage.errorStateImage
            let viewProperties = PaginatedListSelectorViewProperties(navigationBarTitle: navigationBarTitle,
                                                                     noResultsPlaceholderText: noResultsPlaceholderText,
                                                                     noResultsPlaceholderImage: noResultsPlaceholderImage,
                                                                     noResultsPlaceholderImageTintColor: .gray(.shade20))
            let selectorViewController =
                PaginatedListSelectorViewController(viewProperties: viewProperties,
                                                    dataSource: dataSource) { [weak self] selected in
                                                        guard let self = self else {
                                                            return
                                                        }
                                                        self.viewModel.handleTaxClassChange(selected)
                                                        self.refreshViewContent()
            }
            navigationController?.pushViewController(selectorViewController, animated: true)
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sections[section].title == nil {
            return UITableView.automaticDimension
        }

        return Constants.sectionHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let leftText = sections[section].title else {
            return nil
        }

        let headerID = TwoColumnSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? TwoColumnSectionHeaderView else {
            fatalError()
        }

        headerView.leftText = leftText
        headerView.rightText = nil

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rowAtIndexPath(indexPath)

        if row == .datePickerSaleFrom || row == .datePickerSaleTo {
            return Constants.pickerRowHeight
        }

        return UITableView.automaticDimension
    }
}

// MARK: - Cell configuration
//
private extension ProductPriceSettingsViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as UnitInputTableViewCell where row == .price:
            configurePrice(cell: cell)
        case let cell as UnitInputTableViewCell where row == .salePrice:
            configureSalePrice(cell: cell)
        case let cell as SwitchTableViewCell where row == .scheduleSale:
            configureScheduleSale(cell: cell)
        case let cell as SettingTitleAndValueTableViewCell where row == .scheduleSaleFrom:
            configureScheduleSaleFrom(cell: cell)
        case let cell as DatePickerTableViewCell where row == .datePickerSaleFrom:
            configureSaleFromPicker(cell: cell)
        case let cell as SettingTitleAndValueTableViewCell where row == .scheduleSaleTo:
            configureScheduleSaleTo(cell: cell)
        case let cell as DatePickerTableViewCell where row == .datePickerSaleTo:
            configureSaleToPicker(cell: cell)
        case let cell as BasicTableViewCell where row == .removeSaleTo:
            configureRemoveSaleTo(cell: cell)
        case let cell as SettingTitleAndValueTableViewCell where row == .taxStatus:
            configureTaxStatus(cell: cell)
        case let cell as SettingTitleAndValueTableViewCell where row == .taxClass:
            configureTaxClass(cell: cell)
        default:
            fatalError()
            break
        }
    }

    func configurePrice(cell: UnitInputTableViewCell) {
        let cellViewModel = Product.createRegularPriceViewModel(regularPrice: viewModel.regularPrice, using: CurrencySettings.shared) { [weak self] value in
            self?.viewModel.handleRegularPriceChange(value)
        }
        cell.selectionStyle = .none
        cell.configure(viewModel: cellViewModel)
    }

    func configureSalePrice(cell: UnitInputTableViewCell) {
        let cellViewModel = Product.createSalePriceViewModel(salePrice: viewModel.salePrice, using: CurrencySettings.shared) { [weak self] value in
            self?.viewModel.handleSalePriceChange(value)
        }
        cell.selectionStyle = .none
        cell.configure(viewModel: cellViewModel)
    }

    func configureScheduleSale(cell: SwitchTableViewCell) {
        cell.selectionStyle = .none
        cell.title = NSLocalizedString("Schedule sale", comment: "Title of the cell in Product Price Settings > Schedule sale")
        cell.subtitle = NSLocalizedString("Automatically start and end a sale", comment: "Subtitle of the cell in Product Price Settings > Schedule sale")
        cell.isOn = (viewModel.dateOnSaleStart != nil || viewModel.dateOnSaleEnd != nil) ? true : false
        cell.onChange = { [weak self] isOn in
            guard let self = self else {
                return
            }

            self.viewModel.handleScheduleSaleChange(isEnabled: isOn)
            self.refreshViewContent()
        }
    }

    func configureScheduleSaleFrom(cell: SettingTitleAndValueTableViewCell) {
        let title = NSLocalizedString("From", comment: "Title of the cell in Product Price Settings > Schedule sale from a certain date")
        let placeholder = NSLocalizedString("Select start date",
                                            comment: "Placeholder value of the cell in Product Price Settings > Schedule sale from a certain date")
        let value = viewModel.dateOnSaleStart?.toString(dateStyle: .medium, timeStyle: .none, timeZone: timezoneForScheduleSaleDates) ?? placeholder
        cell.updateUI(title: title, value: value)
    }

    func configureSaleFromPicker(cell: DatePickerTableViewCell) {
        if let dateOnSaleStart = viewModel.dateOnSaleStart {
            cell.getPicker().setDate(dateOnSaleStart, animated: false)
        }
        cell.getPicker().timeZone = timezoneForScheduleSaleDates
        cell.onDateSelected = { [weak self] date in
            guard let self = self else {
                return
            }
            self.viewModel.handleSaleStartDateChange(date)

            self.refreshViewContent()
        }
    }

    func configureScheduleSaleTo(cell: SettingTitleAndValueTableViewCell) {
        let title = NSLocalizedString("To", comment: "Title of the cell in Product Price Settings > Schedule sale to a certain date")
        let placeholder = NSLocalizedString("Select end date",
                                            comment: "Placeholder value of the cell in Product Price Settings > Schedule sale to a certain date")
        let value = viewModel.dateOnSaleEnd?.toString(dateStyle: .medium, timeStyle: .none, timeZone: timezoneForScheduleSaleDates) ?? placeholder
        cell.updateUI(title: title, value: value)
    }

    func configureSaleToPicker(cell: DatePickerTableViewCell) {
        if let dateOnSaleEnd = viewModel.dateOnSaleEnd {
            cell.getPicker().setDate(dateOnSaleEnd, animated: false)
        }
        cell.getPicker().timeZone = timezoneForScheduleSaleDates
        cell.onDateSelected = { [weak self] date in
            guard let self = self else {
                return
            }
            self.viewModel.handleSaleEndDateChange(date)
            self.refreshViewContent()
        }
    }

    func configureRemoveSaleTo(cell: BasicTableViewCell) {
        cell.textLabel?.text = NSLocalizedString("Remove end date", comment: "Label action for removing a link from the editor")
        cell.textLabel?.applyLinkBodyStyle()
    }

    func configureTaxStatus(cell: SettingTitleAndValueTableViewCell) {
        let title = NSLocalizedString("Tax status", comment: "Title of the cell in Product Price Settings > Tax status")
        cell.updateUI(title: title, value: viewModel.taxStatus.description)
        cell.accessoryType = .disclosureIndicator
    }

    func configureTaxClass(cell: SettingTitleAndValueTableViewCell) {
        let title = NSLocalizedString("Tax class", comment: "Title of the cell in Product Price Settings > Tax class")
        cell.updateUI(title: title, value: viewModel.taxClass?.name)
        cell.accessoryType = .disclosureIndicator
    }
}

// MARK: - Convenience Methods
//
private extension ProductPriceSettingsViewController {

    func refreshViewContent() {
        configureSections()
        tableView.reloadData()
    }

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    func configureSections() {
        var saleScheduleRows: [Row] = [.scheduleSale]
        if viewModel.dateOnSaleStart != nil || viewModel.dateOnSaleEnd != nil {
            saleScheduleRows.append(contentsOf: [.scheduleSaleFrom])
            if datePickerSaleFromVisible {
                saleScheduleRows.append(contentsOf: [.datePickerSaleFrom])
            }
            saleScheduleRows.append(contentsOf: [.scheduleSaleTo])
            if datePickerSaleToVisible {
                saleScheduleRows.append(contentsOf: [.datePickerSaleTo])
            }
            if viewModel.dateOnSaleEnd != nil {
                saleScheduleRows.append(.removeSaleTo)
            }
        }

        sections = [
        Section(title: NSLocalizedString("Price", comment: "Section header title for product price"), rows: [.price, .salePrice]),
        Section(title: nil, rows: saleScheduleRows),
        Section(title: NSLocalizedString("Tax Settings", comment: "Section header title for product tax settings"), rows: [.taxStatus, .taxClass])
        ]
    }
}

// MARK: - Private Types
//
private extension ProductPriceSettingsViewController {

    struct Section {
        let title: String?
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case price
        case salePrice

        case scheduleSale
        case scheduleSaleFrom
        case datePickerSaleFrom
        case scheduleSaleTo
        case datePickerSaleTo
        case removeSaleTo

        case taxStatus
        case taxClass

        var type: UITableViewCell.Type {
            switch self {
            case .price, .salePrice:
                return UnitInputTableViewCell.self
            case .scheduleSale:
                return SwitchTableViewCell.self
            case .scheduleSaleFrom, .scheduleSaleTo:
                return SettingTitleAndValueTableViewCell.self
            case .datePickerSaleFrom, .datePickerSaleTo:
                return DatePickerTableViewCell.self
            case .taxStatus, .taxClass:
                return SettingTitleAndValueTableViewCell.self
            case .removeSaleTo:
                return BasicTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private struct Constants {
    static let sectionHeight = CGFloat(44)
    static let pickerRowHeight = CGFloat(216)
}
