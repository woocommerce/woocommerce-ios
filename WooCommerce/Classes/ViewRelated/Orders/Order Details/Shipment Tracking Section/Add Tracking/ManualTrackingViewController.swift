import Combine
import UIKit
import Yosemite
import Storage

/// Presents a tracking provider, tracking number and shipment date
///
final class ManualTrackingViewController: UIViewController {
    private var viewModel: ManualTrackingViewModel
    private var datePickerVisible: Bool = false

    @IBOutlet private weak var table: UITableView!

    /// Table Sections to be rendered
    ///
    private lazy var sections = {
        return self.viewModel.sections
    }()

    /// Dedicated NoticePresenter (use this here instead of ServiceLocator.noticePresenter)
    ///
    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        let keyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
            self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
        }
        return keyboardFrameObserver
    }()

    private var valueSubscriptions: Set<AnyCancellable> = []

    init(viewModel: ManualTrackingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
        configureNavigation()
        configureTable()
        startListeningToNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        table.reloadData()
        activateActionButtonIfNecessary()
    }
}


// MARK: - Styles
///
private extension ManualTrackingViewController {
    func configureBackground() {
        view.backgroundColor = .listBackground
    }

    func configureNavigation() {
        configureTitle()
        configureDismissButton()
        configureAddButton()
        // Disables the ability to dismiss the view controller via a pull-down gesture, in order to avoid losing unsaved changes.
        navigationController?.presentationController?.delegate = self
    }

    func configureTitle() {
        title = viewModel.title
    }

    func configureDismissButton() {
        let dismissButtonTitle = NSLocalizedString("Dismiss",
                                                   comment: "Add a note screen - button title for closing the view")
        let leftBarButton = UIBarButtonItem(title: dismissButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(dismissButtonTapped))
        navigationItem.setLeftBarButton(leftBarButton, animated: false)
    }

    func removeProgressIndicator() {
        navigationItem.rightBarButtonItem = nil
    }

    func configureAddButton() {
        guard viewModel.isAdding else {
            return
        }

        let rightBarButton = UIBarButtonItem(title: viewModel.primaryActionTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(primaryButtonTapped))
        navigationItem.setRightBarButton(rightBarButton, animated: false)
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    func configureForCommittingTracking() {
        hideKeyboard()
        configureRightButtonItemAsSpinner()
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    func configureForEditingTracking() {
        removeProgressIndicator()
        configureAddButton()
        navigationItem.rightBarButtonItem?.isEnabled = true
    }

    func configureRightButtonItemAsSpinner() {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()

        let rightBarButton = UIBarButtonItem(customView: activityIndicator)

        navigationItem.setRightBarButton(rightBarButton, animated: true)
    }

    func showKeyboard() {
        table.firstSubview(ofType: UITextField.self)?.becomeFirstResponder()
    }

    func hideKeyboard() {
        table.firstSubview(ofType: UITextField.self)?.resignFirstResponder()
    }

    @objc func dismissButtonTapped() {
        guard !viewModel.hasUnsavedChanges else {
            return displayDismissConfirmationAlert()
        }
        dismiss()
    }

    @objc func primaryButtonTapped() {
        ServiceLocator.analytics.track(.orderShipmentTrackingAddButtonTapped)
        guard viewModel.canCommit else {
            return
        }
        viewModel.isCustom ? addCustomTracking() : addTracking()
        viewModel.saveSelectedShipmentProvider()
    }
}


// MARK: - Table configuration
//
private extension ManualTrackingViewController {
    func configureTable() {
        registerTableViewCells()

        table.estimatedRowHeight = Constants.rowHeight
        table.rowHeight = UITableView.automaticDimension
        table.backgroundColor = .listBackground
        table.dataSource = self
        table.delegate = self
    }

    func registerTableViewCells() {
        viewModel.registerCells(for: table)
    }
}


// MARK: - UITableViewDataSource conformance
//
extension ManualTrackingViewController: UITableViewDataSource {
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

    /// Cells currently configured in the order they appear on screen
    ///
    fileprivate func configure(_ cell: UITableViewCell, for row: AddEditTrackingRow, at indexPath: IndexPath) {
        switch cell {
        case let cell as TitleAndEditableValueTableViewCell where row == .shippingProvider:
            configureShippingProvider(cell: cell)
        case let cell as TitleAndEditableValueTableViewCell where row == .providerName:
            configureProviderName(cell: cell)
        case let cell as TitleAndEditableValueTableViewCell where row == .trackingNumber:
            configureTrackingNumber(cell: cell)
        case let cell as TitleAndEditableValueTableViewCell where row == .trackingLink:
            configureTrackingLink(cell: cell)
        case let cell as TitleAndEditableValueTableViewCell where row == .dateShipped:
            configureDateShipped(cell: cell)
        case let cell as DatePickerTableViewCell where row == .datePicker:
            configurePicker(cell: cell)
        default:
            fatalError()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    private func rowAtIndexPath(_ indexPath: IndexPath) -> AddEditTrackingRow {
        return sections[indexPath.section].rows[indexPath.row]
    }

    private func indexPathForRow(_ row: AddEditTrackingRow, inSection section: Int) -> IndexPath? {
        let requestedSection = sections[section]

        guard let requestedIndex = requestedSection.rows.firstIndex(of: row) else {
            return nil
        }

        return IndexPath(row: requestedIndex, section: section)
    }

    private func configureShippingProvider(cell: TitleAndEditableValueTableViewCell) {
        let cellViewModel = TitleAndEditableValueTableViewCellViewModel(
            title: NSLocalizedString("Shipping carrier", comment: "Add / Edit shipping carrier. Title of cell presenting name"),
            placeholder: NSLocalizedString("Select carrier", comment: "Add the shipping carrier. Placeholder of cell presenting carrier name"),
            initialValue: viewModel.providerCellName,
            allowsEditing: false
        )
        cell.update(viewModel: cellViewModel)
        cell.accessoryType = viewModel.providerCellAccessoryType
    }

    private func configureProviderName(cell: TitleAndEditableValueTableViewCell) {
        let cellViewModel = TitleAndEditableValueTableViewCellViewModel(
            title: NSLocalizedString("Carrier name", comment: "Add Custom shipping carrier. Title of cell presenting the carrier name"),
            placeholder: NSLocalizedString("Enter carrier name", comment: "Add custom shipping carrier. Placeholder of cell presenting carrier name"),
            initialValue: viewModel.providerName
        )
        cell.update(viewModel: cellViewModel)
        cell.accessoryType = .none

        cellViewModel.$value.sink { [weak self] in
            self?.didChangeProviderName(value: $0)
        }.store(in: &valueSubscriptions)
    }

    private func configureTrackingNumber(cell: TitleAndEditableValueTableViewCell) {
        let cellViewModel = TitleAndEditableValueTableViewCellViewModel(
            title: NSLocalizedString("Tracking number", comment: "Add / Edit shipping carrier. Title of cell presenting tracking number"),
            placeholder: NSLocalizedString("Enter tracking number", comment: "Add custom shipping carrier. Placeholder of cell presenting tracking number"),
            initialValue: viewModel.trackingNumber,
            hidesKeyboardOnReturn: true
        )
        cell.update(viewModel: cellViewModel)
        configureTrackingNumberScanAction(on: cell)

        cellViewModel.$value.sink { [weak self] in
            self?.didChangeTrackingNumber(value: $0)
        }.store(in: &valueSubscriptions)
    }

    private func configureTrackingNumberScanAction(on cell: TitleAndEditableValueTableViewCell) {
        guard let icon = UIImage(named: "icon-scan") else {
            return
        }

        let actionButton = UIButton(type: .detailDisclosure)
        actionButton.applyIconButtonStyle(icon: icon)
        actionButton.on(.touchUpInside) { [weak self, weak cell] sender in
            self?.present(ScannerContainerViewController(navigationTitle: Localization.title,
                                                         instructionText: Localization.instructionText,
                                                         onBarcodeScanned: { barcode in
                cell?.updateValue(with: barcode.payloadStringValue)
                self?.dismiss()
            }), animated: true)
        }

        cell.accessoryView = actionButton
    }

    private func configureTrackingLink(cell: TitleAndEditableValueTableViewCell) {
        let cellViewModel = TitleAndEditableValueTableViewCellViewModel(
            title: NSLocalizedString("Tracking link (optional)", comment: "Add custom shipping carrier. Title of cell presenting carrier link"),
            placeholder: NSLocalizedString("Enter tracking link", comment: "Add custom shipping carrier. Placeholder of cell presenting carrier link"),
            initialValue: viewModel.trackingLink
        )
        cell.update(viewModel: cellViewModel)
        cell.accessoryType = .none

        cellViewModel.$value.sink { [weak self] in
            self?.didChangeTrackingLink(value: $0)
        }.store(in: &valueSubscriptions)
    }

    private func configureDateShipped(cell: TitleAndEditableValueTableViewCell) {
        let cellViewModel = TitleAndEditableValueTableViewCellViewModel(
            title: NSLocalizedString("Date shipped", comment: "Add / Edit shipping carrier. Title of cell date shipped"),
            initialValue: viewModel.shipmentDate.toString(dateStyle: .medium, timeStyle: .none),
            allowsEditing: false
        )
        cell.update(viewModel: cellViewModel)
        cell.accessoryType = .none
        cell.separatorInset = datePickerVisible ? Constants.cellSeparatorInset : .zero
    }

    private func configureSecondaryAction(cell: BasicTableViewCell) {
        cell.selectionStyle = .default
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .error
        cell.textLabel?.text = viewModel.secondaryActionTitle
    }

    func configurePicker(cell: DatePickerTableViewCell) {
        cell.onDateSelected = { [weak self] date in
            self?.viewModel.shipmentDate = date
            self?.reloadDate()
        }

        cell.separatorInset = .zero
    }
}


// MARK: - UITableViewDelegate comformance
//
extension ManualTrackingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let lastSection = sections.count - 1
        if section == lastSection {
            return UITableView.automaticDimension
        }
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rowAtIndexPath(indexPath)

        guard row == .datePicker else {
            return UITableView.automaticDimension
        }

        guard datePickerVisible else {
            return CGFloat.leastNonzeroMagnitude
        }

        return DatePickerTableViewCell.getDefaultCellHeight()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        executeAction(for: indexPath)
    }
}


// MARK: - Actions associated to taps in cells
//
private extension ManualTrackingViewController {
    func executeAction(for indexPath: IndexPath) {
        let row = rowAtIndexPath(indexPath)

        if row == .shippingProvider || row == .dateShipped {
            view.endEditing(true)
        }

        if row == .dateShipped && viewModel.isAdding {
            displayDatePicker(at: indexPath)
            return
        }

        if row == .shippingProvider &&
            viewModel.isAdding &&
            !viewModel.isCustom {
            showAllShipmentProviders()
        }
    }

    func displayDatePicker(at indexPath: IndexPath) {
        datePickerVisible = true
        reloadDatePicker(at: indexPath)
        table.scrollToRow(at: indexPath, at: .top, animated: true)
    }

    func showAllShipmentProviders() {
        let shippingProviders = ShippingProvidersViewModel(order: viewModel.order,
                                                           selectedProvider: viewModel.shipmentProvider,
                                                           selectedProviderGroupName: viewModel.shipmentProviderGroupName)
        let shippingList = ShipmentProvidersViewController(viewModel: shippingProviders, delegate: self)
        navigationController?.pushViewController(shippingList, animated: true)
    }

    func reloadDatePicker(at indexPath: IndexPath) {
        table.beginUpdates()
        table.reloadRows(at: [indexPath], with: .fade)
        table.endUpdates()
    }

    func reloadDate() {
        guard let dateRowIndex = indexPathForRow(.dateShipped, inSection: 0) else {
            return
        }

        table.beginUpdates()
        table.reloadRows(at: [dateRowIndex], with: .none)
        table.endUpdates()
    }
}


// MARK: - Conformance to delegate of List of Shipment providers.
//
extension ManualTrackingViewController: ShipmentProviderListDelegate {
    func shipmentProviderList(_ list: ShipmentProvidersViewController, didSelect: Yosemite.ShipmentTrackingProvider, groupName: String) {
        ServiceLocator.analytics.track(.orderShipmentTrackingCarrierSelected,
                                  withProperties: ["option": didSelect.name])

        viewModel.shipmentProvider = didSelect
        viewModel.shipmentProviderGroupName = groupName
    }
}


// MARK: - Tracking number textfield
//
private extension ManualTrackingViewController {
    func didChangeProviderName(value: String?) {
        guard let newProviderName = value else {
            return
        }

        viewModel.providerName = newProviderName
        activateActionButtonIfNecessary()
    }

    func didChangeTrackingNumber(value: String?) {
        guard let newTrackingNumber = value else {
            return
        }

        viewModel.trackingNumber = newTrackingNumber
        activateActionButtonIfNecessary()
    }

    func didChangeTrackingLink(value: String?) {
        guard let newTrackingLink = value else {
            return
        }

        viewModel.trackingLink = newTrackingLink.addHTTPSSchemeIfNecessary()
        activateActionButtonIfNecessary()
    }
}


// MARK: - Navigation bar management
//
/// Activates the action button (Add/Edit) if there is enough data to add or edit a shipment tracking
private extension ManualTrackingViewController {
    private func activateActionButtonIfNecessary() {
        navigationItem.rightBarButtonItem?.isEnabled = viewModel.canCommit
    }
}

// MARK: - UISheetPresentationControllerDelegate comformance
//
extension ManualTrackingViewController: UISheetPresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        viewModel.hasUnsavedChanges == false
    }
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        displayDismissConfirmationAlert()
    }
}


// MARK: - Actions!
//
private extension ManualTrackingViewController {
    func addTracking() {
        configureForCommittingTracking()
        guard let groupName = viewModel.shipmentProviderGroupName,
            let providerName = viewModel.shipmentProvider?.name,
            let trackingNumber = viewModel.trackingNumber else {
                return
        }


        let siteID = viewModel.order.siteID
        let orderID = viewModel.order.orderID
        let statusKey = viewModel.order.status
        let dateShipped = DateFormatter
            .Defaults
            .yearMonthDayDateFormatter
            .string(from: viewModel.shipmentDate)

        ServiceLocator.analytics.track(.orderTrackingAdd, withProperties: ["id": orderID,
                                                                           "status": statusKey.rawValue,
                                                                           "carrier": providerName])

        let addTrackingAction = ShipmentAction.addTracking(siteID: siteID,
                                                           orderID: orderID,
                                                           providerGroupName: groupName,
                                                           providerName: providerName,
                                                           dateShipped: dateShipped,
                                                           trackingNumber: trackingNumber) { [weak self] error in

                                                            if let error = error {
                                                                DDLogError("⛔️ Add Tracking Failure: orderID \(orderID). Error: \(error)")

                                                                ServiceLocator.analytics.track(.orderTrackingAddFailed,
                                                                                          withError: error)

                                                                self?.configureForEditingTracking()

                                                                self?.displayAddErrorNotice(orderID: orderID)
                                                                return
                                                            }

                                                        ServiceLocator.analytics.track(.orderTrackingAddSuccess)

                                                            self?.dismiss()
        }

        ServiceLocator.stores.dispatch(addTrackingAction)
    }

    func addCustomTracking() {
        guard let providerName = viewModel.providerName,
            let trackingNumber = viewModel.trackingNumber else {
                //TODO. Present notice
            return
        }
        configureForCommittingTracking()

        let siteID = viewModel.order.siteID
        let orderID = viewModel.order.orderID
        let statusKey = viewModel.order.status
        let trackingLink = viewModel.trackingLink ?? ""
        let dateShipped = DateFormatter
            .Defaults
            .yearMonthDayDateFormatter
            .string(from: viewModel.shipmentDate)

        ServiceLocator.analytics.track(.orderTrackingAdd, withProperties: ["id": orderID,
                                                                           "status": statusKey.rawValue,
                                                                           "carrier": providerName])

        let action = ShipmentAction.addCustomTracking(siteID: siteID,
                                                      orderID: orderID,
                                                      trackingProvider: providerName,
                                                      trackingNumber: trackingNumber,
                                                      trackingURL: trackingLink,
                                                      dateShipped: dateShipped) { [weak self] error in
                                                        if let error = error {
                                                            DDLogError("⛔️ Add Tracking Failure: orderID \(orderID). Error: \(error)")

                                                            ServiceLocator.analytics.track(.orderTrackingAddFailed,
                                                                                      withError: error)

                                                            self?.configureForEditingTracking()

                                                            self?.displayAddErrorNotice(orderID: orderID)
                                                            return
                                                        }

                                                        ServiceLocator.analytics.track(.orderTrackingAddSuccess)

                                                        self?.dismiss()
        }

        ServiceLocator.stores.dispatch(action)

    }
    func displayDismissConfirmationAlert() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self,
                                                           onDiscard: {[weak self] in self?.dismiss(animated: true)}
        )
    }

    func dismiss() {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: - Keyboard management
//
private extension ManualTrackingViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

extension ManualTrackingViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return table
    }
}

// MARK: - Error handling
//
private extension ManualTrackingViewController {
    /// Displays the `Unable to Add tracking` Notice.
    ///
    func displayAddErrorNotice(orderID: Int64) {
        let titleFormat = NSLocalizedString(
            "Unable to add tracking to order #%1$d",
            comment: "Content of error presented when Add Shipment Tracking Action Failed. "
                + "It reads: Unable to add tracking to order #{order number}. "
                + "Parameters: %1$d - order number"
        )
        let title = String.localizedStringWithFormat(titleFormat, orderID)
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: title,
                            message: nil,
                            feedbackType: .error,
                            actionTitle: actionTitle) { [weak self] in
            self?.primaryButtonTapped()
        }

        noticePresenter.enqueue(notice: notice)
    }
}

private struct Constants {
    static let rowHeight = CGFloat(74)
    static let pickerRowHeight = CGFloat(216)
    static let disabledAlpha = CGFloat(0.7)
    static let enabledAlpha = CGFloat(1.0)
    static let cellSeparatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
}


/// Testability
///
extension ManualTrackingViewController {
    func getTable() -> UITableView {
        return table
    }
}

private extension ManualTrackingViewController {
    enum Localization {
        static let title = NSLocalizedString("ManualTrackingViewController.scanView.titleView",
                                             value: "Scan barcode or QR Code with tracking number",
                                             comment: "Navigation bar title for scanning a barcode or QR Code to use as an order tracking number.")
        static let instructionText = NSLocalizedString("ManualTrackingViewController.scanView.instructionText",
                                                       value: "Scan Tracking Barcode or QR Code",
                                                       comment: "The instruction text below the scan area in the barcode scanner for order tracking number.")
    }
}
