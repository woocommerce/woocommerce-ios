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
        let keyboardFrameObserver = KeyboardFrameObserver(onKeyboardFrameUpdate: handleKeyboardFrameUpdate(keyboardFrame:))
        return keyboardFrameObserver
    }()

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
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func configureNavigation() {
        configureTitle()
        configureDismissButton()
        configureBackButton()
        configureAddButton()
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
        leftBarButton.tintColor = .white
        navigationItem.setLeftBarButton(leftBarButton, animated: false)
    }

    func configureBackButton() {
        // Don't show the title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
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
        rightBarButton.tintColor = .white
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
        let activityIndicator = UIActivityIndicatorView(style: .white)
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
        dismiss()
    }

    @objc func primaryButtonTapped() {
        ServiceLocator.analytics.track(.orderShipmentTrackingAddButtonTapped)
        viewModel.isCustom ? addCustomTracking() : addTracking()
    }
}


// MARK: - Table configuration
//
private extension ManualTrackingViewController {
    func configureTable() {
        registerTableViewCells()

        table.estimatedRowHeight = Constants.rowHeight
        table.rowHeight = UITableView.automaticDimension
        table.backgroundColor = StyleManager.tableViewBackgroundColor
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
        cell.title.text = NSLocalizedString("Shipping provider", comment: "Add / Edit shipping provider. Title of cell presenting name")
        cell.value.text = viewModel.providerCellName

        cell.value.isEnabled = false
        cell.accessoryType = viewModel.providerCellAccessoryType
    }

    private func configureProviderName(cell: TitleAndEditableValueTableViewCell) {
        cell.title.text = NSLocalizedString("Provider name", comment: "Add Custom shipping provider. Title of cell presenting the provider name")
        cell.value.placeholder = NSLocalizedString("Enter provider name", comment: "Add custom shipping provider. Placeholder of cell presenting provider name")

        cell.value.text = viewModel.providerName
        cell.value.isEnabled = true

        cell.value.addTarget(self, action: #selector(didChangeProviderName), for: .editingChanged)
        cell.accessoryType = .none
    }

    private func configureTrackingNumber(cell: TitleAndEditableValueTableViewCell) {
        cell.title.text = NSLocalizedString("Tracking number", comment: "Add / Edit shipping provider. Title of cell presenting tracking number")

        cell.value.placeholder = NSLocalizedString("Enter tracking number",
                                                   comment: "Add custom shipping provider. Placeholder of cell presenting tracking number")
        cell.value.text = viewModel.trackingNumber
        cell.value.isEnabled = true

        cell.value.addTarget(self, action: #selector(didChangeTrackingNumber), for: .editingChanged)
        cell.accessoryType = .none
    }

    private func configureTrackingLink(cell: TitleAndEditableValueTableViewCell) {
        cell.title.text = NSLocalizedString("Tracking link (optional)", comment: "Add custom shipping provider. Title of cell presenting tracking link")

        cell.value.placeholder = NSLocalizedString("Enter tracking link", comment: "Add custom shipping provider. Placeholder of cell presenting tracking link")

        cell.value.text = viewModel.trackingLink

        cell.value.isEnabled = true
        cell.value.addTarget(self, action: #selector(didChangeTrackingLink), for: .editingChanged)

        cell.accessoryType = .none
    }

    private func configureDateShipped(cell: TitleAndEditableValueTableViewCell) {
        cell.title.text = NSLocalizedString("Date shipped", comment: "Add / Edit shipping provider. Title of cell date shipped")

        cell.value.text = viewModel.shipmentDate.toString(dateStyle: .medium, timeStyle: .none)

        cell.value.isEnabled = false
        cell.accessoryType = .none

        cell.separatorInset = datePickerVisible ? Constants.cellSeparatorInset : .zero
    }

    private func configureSecondaryAction(cell: BasicTableViewCell) {
        cell.selectionStyle = .default
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = StyleManager.destructiveActionColor
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

        return Constants.pickerRowHeight
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rowAtIndexPath(indexPath)

        guard row == .datePicker else {
            return Constants.rowHeight
        }

        guard datePickerVisible else {
            return CGFloat.leastNonzeroMagnitude
        }

        return Constants.pickerRowHeight
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
        let shippingProviders = ShippingProvidersViewModel(order: viewModel.order)
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
    @objc func didChangeProviderName(sender: UITextField) {
        guard let newProviderName = sender.text else {
            return
        }

        viewModel.providerName = newProviderName
        activateActionButtonIfNecessary()
    }

    @objc func didChangeTrackingNumber(sender: UITextField) {
        guard let newTrackingNumber = sender.text else {
            return
        }

        viewModel.trackingNumber = newTrackingNumber
        activateActionButtonIfNecessary()
    }

    @objc func didChangeTrackingLink(sender: UITextField) {
        guard let newTrackingLink = sender.text else {
            return
        }

        viewModel.trackingLink = newTrackingLink.addHTTPSSchemeIfNecessary()
        activateActionButtonIfNecessary()
    }
}


// MARK: - Navigation bar management
//
/// Activates the action button (Add/Edit) if there is anough data to add or edit a shipment tracking
private extension ManualTrackingViewController {
    private func activateActionButtonIfNecessary() {
        navigationItem.rightBarButtonItem?.isEnabled = viewModel.canCommit
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
        let statusKey = viewModel.order.statusKey
        let dateShipped = DateFormatter
            .Defaults
            .yearMonthDayDateFormatter
            .string(from: viewModel.shipmentDate)

        ServiceLocator.analytics.track(.orderTrackingAdd, withProperties: ["id": orderID,
                                                                      "status": statusKey,
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
        let statusKey = viewModel.order.statusKey
        let trackingLink = viewModel.trackingLink ?? ""
        let dateShipped = DateFormatter
            .Defaults
            .yearMonthDayDateFormatter
            .string(from: viewModel.shipmentDate)

        ServiceLocator.analytics.track(.orderTrackingAdd, withProperties: ["id": orderID,
                                                                      "status": statusKey,
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
    func displayAddErrorNotice(orderID: Int) {
        let title = NSLocalizedString(
            "Unable to add tracking to order #\(orderID)",
            comment: "Content of error presented when Add Shipment Tracking Action Failed. It reads: Unable to add tracking to order #{order number}"
        )
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
