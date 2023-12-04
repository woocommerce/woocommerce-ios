import UIKit
import Yosemite

// MARK: - ProductPriceSettingsViewController
//
final class ProductPriceSettingsViewController: UIViewController {

    @IBOutlet weak private var tableView: UITableView!

    /// Product Price Settings dedicated NoticePresenter (use this here instead of ServiceLocator.noticePresenter due to modal page sheet situations)
    ///
    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

    private let siteID: Int64

    private let viewModel: ProductPriceSettingsViewModelOutput & ProductPriceSettingsActionHandler

    // Timezone of the website
    //
    private let timezoneForScheduleSaleDates = TimeZone.siteTimezone

    /// Table Sections to be rendered
    ///
    private var sections: [Section] = []

    // Completion callback
    //
    typealias Completion = (_ regularPrice: String?,
                            _ subscriptionPeriod: SubscriptionPeriod?,
                            _ subscriptionPeriodInterval: String?,
                            _ subscriptionSignupFee: String?,
                            _ salePrice: String?,
                            _ dateOnSaleStart: Date?,
                            _ dateOnSaleEnd: Date?,
                            _ taxStatus: ProductTaxStatus,
                            _ taxClass: TaxClass?,
                            _ hasUnsavedChanges: Bool) -> Void
    private let onCompletion: Completion

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        let keyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
            self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
        }
        return keyboardFrameObserver
    }()

    private lazy var subscriptionPeriodToolbar: UIToolbar = {
        // Setting explicit frame size to avoid constraint conflicts.
        let toolBar = UIToolbar(frame: .init(origin: .zero,
                                             size: .init(width: UIScreen.main.bounds.width,
                                                         height: Constants.subscriptionPeriodToolbarHeight)))
        let doneButton = UIBarButtonItem(title: Localization.subscriptionPeriodToolBarButton,
                                         style: .done,
                                         target: self,
                                         action: #selector(self.onSubscriptionPeriodUpdateDone))
        doneButton.tintColor = .accent
        toolBar.setItems([.flexibleSpace(), doneButton], animated: false)
        return toolBar
    }()

    private var subscriptionPeriodPickerUseCase: ProductSubscriptionPeriodPickerUseCase?

    /// Init
    ///
    init(product: ProductFormDataModel & TaxClassRequestable, completion: @escaping Completion) {
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
        handleSwipeBackGesture()
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
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground
        tableView.keyboardDismissMode = .onDragWithAccessory

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
            tableView.registerNib(for: row.type)
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

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    @objc private func completeUpdating() {
        viewModel.completeUpdating(
            onCompletion: { [weak self] in
                self?.onCompletion($0, $1, $2, $3, $4, $5, $6, $7, $8, $9)
            },
            onError: { [weak self] error in
                switch error {
                case .salePriceWithoutRegularPrice:
                    self?.displaySalePriceWithoutRegularPriceErrorNotice()
                case .salePriceHigherThanRegularPrice:
                    self?.displaySalePriceErrorNotice()
                case .newSaleWithEmptySalePrice:
                    self?.displayMissingSalePriceErrorNotice()
                    break
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
        let message = NSLocalizedString("The sale price can't be added without the regular price.",
                                        comment: "Product price error notice message, when the sale price is added but the regular price is not")
        displayNotice(for: message)
    }

    /// Displays a Notice onscreen, indicating that the sale price need to be higher than the regular price
    ///
    func displaySalePriceErrorNotice() {
        let message = NSLocalizedString("The sale price should be lower than the regular price.",
                                        comment: "Product price error notice message, when the sale price is higher than the regular price")
        displayNotice(for: message)
    }

    /// Displays a Notice onscreen, indicating that the sale price must be set in order to create a new sale
    ///
    func displayMissingSalePriceErrorNotice() {
        let message = NSLocalizedString("Please enter a sale price for the scheduled sale",
                                        comment: "Product price error notice message, when the sale price was not set during a sale setup")
        displayNotice(for: message)
    }

    /// Displays a Notice onscreen for a given message
    ///
    func displayNotice(for message: String) {
        view.endEditing(true)
        let notice = Notice(title: message, feedbackType: .error)
        noticePresenter.enqueue(notice: notice)
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
            viewModel.didTapScheduleSaleFromRow()
            refreshViewContent()
        case .scheduleSaleTo:
            viewModel.didTapScheduleSaleToRow()
            refreshViewContent()
        case .removeSaleTo:
            viewModel.handleSaleEndDateChange(nil)
            refreshViewContent()
        case .taxStatus:
            let command = ProductTaxStatusListSelectorCommand(selected: viewModel.taxStatus)
            let listSelectorViewController = ListSelectorViewController(command: command) { [weak self] selected in
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
                                                                     noResultsPlaceholderImageTintColor: .gray(.shade20),
                                                                     tableViewStyle: .grouped)
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
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
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
            return DatePickerTableViewCell.getDefaultCellHeight()
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
        case let cell as TitleAndValueTableViewCell where row == .scheduleSaleFrom:
            configureScheduleSaleFrom(cell: cell)
        case let cell as DatePickerTableViewCell where row == .datePickerSaleFrom:
            configureSaleFromPicker(cell: cell)
        case let cell as TitleAndValueTableViewCell where row == .scheduleSaleTo:
            configureScheduleSaleTo(cell: cell)
        case let cell as DatePickerTableViewCell where row == .datePickerSaleTo:
            configureSaleToPicker(cell: cell)
        case let cell as BasicTableViewCell where row == .removeSaleTo:
            configureRemoveSaleTo(cell: cell)
        case let cell as TitleAndValueTableViewCell where row == .taxStatus:
            configureTaxStatus(cell: cell)
        case let cell as TitleAndValueTableViewCell where row == .taxClass:
            configureTaxClass(cell: cell)
        case let cell as TitleAndTextFieldTableViewCell where row == .subscriptionPeriod:
            configureSubscriptionPeriod(cell: cell)
        case let cell as UnitInputTableViewCell where row == .subscriptionSignupFee:
            configureSubscriptionSignupFee(cell: cell)
        default:
            fatalError()
            break
        }
    }

    func configurePrice(cell: UnitInputTableViewCell) {
        let cellViewModel = Product.createRegularPriceViewModel(regularPrice: viewModel.regularPrice,
                                                                using: ServiceLocator.currencySettings) { [weak self] value in
            self?.viewModel.handleRegularPriceChange(value)
        }
        cell.selectionStyle = .none
        cell.configure(viewModel: cellViewModel)
    }

    func configureSubscriptionPeriod(cell: TitleAndTextFieldTableViewCell) {
        let useCase = ProductSubscriptionPeriodPickerUseCase(
            initialPeriod: viewModel.subscriptionPeriod,
            initialInterval: viewModel.subscriptionPeriodInterval,
            updateHandler: { [weak self] period, interval in
                self?.viewModel.handleSubscriptionPeriodChange(interval: interval, period: period)
            }
        )
        self.subscriptionPeriodPickerUseCase = useCase

        cell.configure(viewModel: .init(title: Localization.billingInterval,
                                        text: viewModel.subscriptionPeriodDescription,
                                        placeholder: nil,
                                        textFieldAlignment: .trailing,
                                        inputView: useCase.pickerView,
                                        inputAccessoryView: subscriptionPeriodToolbar,
                                        onEditingEnd: { [weak self] in
            self?.refreshViewContent()
        }))
    }

    func configureSubscriptionSignupFee(cell: UnitInputTableViewCell) {
        let cellViewModel = Product.createSubscriptionSignupFeeViewModel(
            fee: viewModel.subscriptionSignupFee,
            using: ServiceLocator.currencySettings
        ) { [weak self] fee in
            self?.viewModel.handleSubscriptionSignupFeeChange(fee)
        }
        cell.selectionStyle = .none
        cell.configure(viewModel: cellViewModel)
    }

    func configureSalePrice(cell: UnitInputTableViewCell) {
        let cellViewModel = Product.createSalePriceViewModel(salePrice: viewModel.salePrice, using: ServiceLocator.currencySettings) { [weak self] value in
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

    func configureScheduleSaleFrom(cell: TitleAndValueTableViewCell) {
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

    func configureScheduleSaleTo(cell: TitleAndValueTableViewCell) {
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

    func configureTaxStatus(cell: TitleAndValueTableViewCell) {
        let title = NSLocalizedString("Tax status", comment: "Title of the cell in Product Price Settings > Tax status")
        cell.updateUI(title: title, value: viewModel.taxStatus.description)
        cell.accessoryType = .disclosureIndicator
    }

    func configureTaxClass(cell: TitleAndValueTableViewCell) {
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
        sections = viewModel.sections
    }

    @objc
    func onSubscriptionPeriodUpdateDone() {
        view.endEditing(true)
    }
}

// MARK: - Private Types
//
extension ProductPriceSettingsViewController {

    struct Section: Equatable {
        let title: String?
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case price
        case subscriptionPeriod
        case subscriptionSignupFee
        case salePrice

        case scheduleSale
        case scheduleSaleFrom
        case datePickerSaleFrom
        case scheduleSaleTo
        case datePickerSaleTo
        case removeSaleTo

        case taxStatus
        case taxClass

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .price, .salePrice, .subscriptionSignupFee:
                return UnitInputTableViewCell.self
            case .scheduleSale:
                return SwitchTableViewCell.self
            case .scheduleSaleFrom, .scheduleSaleTo:
                return TitleAndValueTableViewCell.self
            case .datePickerSaleFrom, .datePickerSaleTo:
                return DatePickerTableViewCell.self
            case .taxStatus, .taxClass:
                return TitleAndValueTableViewCell.self
            case .removeSaleTo:
                return BasicTableViewCell.self
            case .subscriptionPeriod:
                return TitleAndTextFieldTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private struct Constants {
    static let sectionHeight = CGFloat(44)
    static let subscriptionPeriodToolbarHeight: CGFloat = 35
}

private extension ProductPriceSettingsViewController {
    enum Localization {
        static let billingInterval = NSLocalizedString(
            "productPriceSettingsViewController.billingIntervalRowTitle",
            value: "Billing interval",
            comment: "Title of the billing interval row on the Product Price screen"
        )
        static let subscriptionPeriodToolBarButton = NSLocalizedString(
            "productPriceSettingsViewController.subscriptionPeriodToolBarButton",
            value: "Done",
            comment: "Button on the toolbar of the subscription period picker view on the Product Price screen"
        )
    }
}
