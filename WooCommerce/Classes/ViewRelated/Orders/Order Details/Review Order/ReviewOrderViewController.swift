import SafariServices
import UIKit
import Yosemite

/// View Control for Review Order screen
/// This screen is shown when Mark Order Complete button is tapped
///
final class ReviewOrderViewController: UIViewController {

    /// View model to provide order info for review
    ///
    private let viewModel: ReviewOrderViewModel

    /// Handler block to call when order is marked completed
    ///
    private let markOrderCompleteHandler: () -> Void

    /// Image service needed for order item cells
    ///
    private let imageService: ImageService = ServiceLocator.imageService

    /// Table view to display order details
    ///
    @IBOutlet private var tableView: UITableView!

    /// Haptic Feedback!
    ///
    private let hapticGenerator = UINotificationFeedbackGenerator()

    /// Reuse notices from Order Details
    ///
    private let notices = OrderDetailsNotices()

    /// Footer of the table view
    ///
    private lazy var footerView: UIView = configureTableFooterView()

    init(viewModel: ReviewOrderViewModel, markOrderCompleteHandler: @escaping () -> Void) {
        self.viewModel = viewModel
        self.markOrderCompleteHandler = markOrderCompleteHandler
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureTableView()
        configureViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.syncTrackingsHidingAddButtonIfNecessary { [weak self] in
            self?.tableView.reloadData()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.updateFooterHeight()
    }

    override var shouldShowOfflineBanner: Bool {
        return true
    }
}

// MARK: - UI Configuration
//
private extension ReviewOrderViewController {

    func configureViewModel() {
        viewModel.configureResultsControllers { [weak self] in
            self?.tableView.reloadData()
        }
    }

    func configureNavigation() {
        title = Localization.screenTitle
    }

    func configureTableView() {
        registerHeaderTypes()
        registerCellTypes()
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = footerView

        // workaround to fix extra space on top
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))

        tableView.dataSource = self
        tableView.delegate = self
    }

    func configureTableFooterView() -> UIView {
        let containerView = UIView(frame: .zero)
        containerView.backgroundColor = .listBackground

        let emailLabel = UILabel(frame: .zero)
        emailLabel.text = Localization.emailMessage
        emailLabel.applySecondaryBodyStyle()
        emailLabel.numberOfLines = 2
        emailLabel.lineBreakMode = .byWordWrapping
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(emailLabel)

        NSLayoutConstraint.activate([
            emailLabel.leadingAnchor.constraint(equalTo: containerView.safeLeadingAnchor, constant: 16),
            emailLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            containerView.safeTrailingAnchor.constraint(equalTo: emailLabel.trailingAnchor, constant: 16)
        ])

        let actionButton = UIButton(frame: .zero)
        actionButton.applyPrimaryButtonStyle()
        actionButton.setTitle(Localization.markOrderCompleteTitle, for: .normal)
        actionButton.addTarget(self, action: #selector(markOrderComplete), for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(actionButton)

        NSLayoutConstraint.activate([
            actionButton.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 16),
            actionButton.leadingAnchor.constraint(equalTo: containerView.safeLeadingAnchor, constant: 16),
            containerView.safeBottomAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 24),
            containerView.safeTrailingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: 16)
        ])

        return containerView
    }

    func registerHeaderTypes() {
        let allHeaderTypes: [UITableViewHeaderFooterView.Type] = {
            [PrimarySectionHeaderView.self,
             TwoColumnSectionHeaderView.self]
        }()

        for headerType in allHeaderTypes {
            tableView.register(headerType.loadNib(), forHeaderFooterViewReuseIdentifier: headerType.reuseIdentifier)
        }
    }

    func registerCellTypes() {
        let allCellTypes: [UITableViewCell.Type] = {
            [ProductDetailsTableViewCell.self,
             CustomerNoteTableViewCell.self,
             CustomerInfoTableViewCell.self,
             WooBasicTableViewCell.self,
             OrderTrackingTableViewCell.self,
             LeftImageTableViewCell.self]
        }()

        for cellType in allCellTypes {
            tableView.registerNib(for: cellType)
        }
    }
}

// MARK: - UITableViewDatasource conformance
//
extension ReviewOrderViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.cellType.reuseIdentifier, for: indexPath)
        setup(cell: cell, for: row, at: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate conformance
//
extension ReviewOrderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = viewModel.sections[safe: section] else {
            return nil
        }

        let reuseIdentifier = section.headerType.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier) else {
            assertionFailure("Could not find section header view for reuseIdentifier \(reuseIdentifier)")
            return nil
        }

        switch headerView {
        case let headerView as PrimarySectionHeaderView:
            switch section.category {
            case .products:
                let sectionTitle = viewModel.aggregateOrderItems.count > 1 ? Localization.productsSectionTitle : Localization.productSectionTitle
                headerView.configure(title: sectionTitle)
            case .customerInformation, .tracking:
                assertionFailure("Unexpected category of type \(headerView.self)")
            }
        case let headerView as TwoColumnSectionHeaderView:
            switch section.category {
            case .customerInformation:
                headerView.leftText = Localization.customerSectionTitle
                headerView.rightText = nil
            case .tracking:
                headerView.leftText = Localization.trackingSectionTitle
                headerView.rightText = nil
            case .products:
                assertionFailure("Unexpected category of type \(headerView.self)")
            }
        default:
            assertionFailure("Unexpected headerView type \(headerView.self)")
            return nil
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = viewModel.sections[safe: indexPath.section]?.rows[safe: indexPath.row] else {
            return
        }
        switch row {
        case .billingDetail:
            billingInformationTapped()
        case .trackingAdd:
            addTrackingTapped()
        default:
            break
        }
    }
}

// MARK: - Setup cells for the table view
//
private extension ReviewOrderViewController {
    /// Setup a given UITableViewCell instance to actually display the specified Row's Payload.
    ///
    func setup(cell: UITableViewCell, for row: ReviewOrderViewModel.Row, at indexPath: IndexPath) {
        switch row {
        case .orderItem(let item):
            setupOrderItemCell(cell, with: item)
        case .customerNote(let text):
            setupCustomerNoteCell(cell, with: text)
        case .shippingAddress(let address):
            setupAddressCell(cell, with: address)
        case .shippingMethod(let method):
            setupShippingMethodCell(cell, method: method)
        case .billingDetail:
            setupBillingDetail(cell)
        case .trackingAdd:
            setupTrackingAddCell(cell)
        case .tracking:
            setupTrackingCell(cell, at: indexPath)
        }
    }

    /// Setup: Order item Cell
    ///
    private func setupOrderItemCell(_ cell: UITableViewCell, with item: AggregateOrderItem) {
        guard let cell = cell as? ProductDetailsTableViewCell else {
            fatalError("⛔ Incorrect cell type for Product Details cell")
        }

        let itemViewModel = viewModel.productDetailsCellViewModel(for: item)
        cell.configure(item: itemViewModel, imageService: imageService)
        cell.onViewAddOnsTouchUp = { [weak self] in
            guard let self = self else { return }
            self.itemAddOnsButtonTapped(addOns: self.viewModel.filterAddons(for: item))
        }
    }

    /// Setup: Customer Note Cell
    ///
    private func setupCustomerNoteCell(_ cell: UITableViewCell, with note: String) {
        guard let cell = cell as? CustomerNoteTableViewCell else {
            fatalError("⛔ Incorrect cell type for Customer Note cell")
        }

        cell.headline = Localization.customerNoteTitle
        let localizedBody = String.localizedStringWithFormat(
            NSLocalizedString("“%@”",
                              comment: "Customer note, wrapped in quotes"),
            note)
        cell.body = localizedBody
        cell.selectionStyle = .none
    }

    /// Setup: Address Cell
    ///
    private func setupAddressCell(_ cell: UITableViewCell, with address: Address?) {
        guard let cell = cell as? CustomerInfoTableViewCell else {
            fatalError("⛔ Incorrect cell type for Address cell")
        }
        cell.title = Localization.shippingAddressTitle
        cell.name = address?.fullNameWithCompany
        cell.address = address?.formattedPostalAddress ?? Localization.noAddressCellTitle
    }

    /// Setup: Shipping Method cell
    ///
    func setupShippingMethodCell(_ cell: UITableViewCell, method: String?) {
        guard let cell = cell as? CustomerNoteTableViewCell else {
            fatalError("⛔ Incorrect cell type for Shipping Method cell")
        }

        cell.headline = Localization.shippingMethodTitle
        cell.body = method?.strippedHTML
        cell.selectionStyle = .none
    }

    /// Setup: Billing Detail cell
    ///
    func setupBillingDetail(_ cell: UITableViewCell) {
        guard let cell = cell as? WooBasicTableViewCell else {
            fatalError("⛔ Incorrect cell type for Billing Detail cell")
        }
        cell.bodyLabel?.text = Localization.showBillingTitle
        cell.applyPlainTextStyle()
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default

        cell.accessibilityTraits = .button
        cell.accessibilityLabel = Localization.showBillingAccessibilityLabel
        cell.accessibilityHint = Localization.showBillingAccessibilityHint
    }

    /// Setup: Add Tracking Cell
    ///
    func setupTrackingAddCell(_ cell: UITableViewCell) {
        guard let cell = cell as? LeftImageTableViewCell else {
            fatalError("⛔ Incorrect cell type for Add Tracking cell")
        }

        let cellTextContent = Localization.addTrackingTitle
        cell.leftImage = .addOutlineImage
        cell.imageView?.tintColor = .accent
        cell.labelText = cellTextContent

        cell.isAccessibilityElement = true

        cell.accessibilityLabel = cellTextContent
        cell.accessibilityTraits = .button
        cell.accessibilityHint = Localization.addTrackingAccessibilityHint
    }

    /// Setup: Shipment Tracking cells
    ///
    func setupTrackingCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        guard let cell = cell as? OrderTrackingTableViewCell else {
            fatalError("⛔ Incorrect cell type for Tracking cell")
        }
        guard let tracking = viewModel.orderTracking(at: indexPath.row) else { return }

        cell.topText = tracking.trackingProvider
        cell.middleText = tracking.trackingNumber

        cell.onEllipsisTouchUp = { [weak self] in
            self?.shipmentTrackingTapped(at: indexPath)
        }

        if let dateShipped = tracking.dateShipped?.toString(dateStyle: .long, timeStyle: .none) {
            cell.bottomText = String.localizedStringWithFormat(Localization.shippedTitle, dateShipped)
        } else {
            cell.bottomText = Localization.notShippedYetTitle
        }
    }
}

// MARK: - Actions
//
private extension ReviewOrderViewController {
    /// Show addon list screen
    ///
    func itemAddOnsButtonTapped(addOns: [OrderItemAttribute]) {
        let addOnsViewModel = OrderAddOnListI1ViewModel(attributes: addOns)
        let addOnsController = OrderAddOnsListViewController(viewModel: addOnsViewModel)
        let navigationController = WooNavigationController(rootViewController: addOnsController)
        present(navigationController, animated: true, completion: nil)
    }

    /// Show billing information screen
    ///
    func billingInformationTapped() {
        let billingInformationViewController = BillingInformationViewController(order: viewModel.order, editingEnabled: false)
        navigationController?.pushViewController(billingInformationViewController, animated: true)
    }

    /// Handle add tracking
    ///
    func addTrackingTapped() {
        let addTrackingViewModel = AddTrackingViewModel(order: viewModel.order)
        let addTracking = ManualTrackingViewController(viewModel: addTrackingViewModel)
        let navController = WooNavigationController(rootViewController: addTracking)
        present(navController, animated: true, completion: nil)
    }

    /// Handle shipment tracking tapped
    ///
    func shipmentTrackingTapped(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? OrderTrackingTableViewCell else {
            return
        }

        guard let tracking = viewModel.orderTracking(at: indexPath.row) else {
            return
        }

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        actionSheet.addCancelActionWithTitle(TrackingAction.dismiss)

        actionSheet.addDefaultActionWithTitle(TrackingAction.copyTrackingNumber) { [weak self] _ in
            self?.sendToPasteboard(tracking.trackingNumber, includeTrailingNewline: false)
        }

        if tracking.trackingURL?.isEmpty == false {
            actionSheet.addDefaultActionWithTitle(TrackingAction.trackShipment) { [weak self] _ in
                self?.openTrackingDetails(tracking)
            }
        }

        actionSheet.addDestructiveActionWithTitle(TrackingAction.deleteTracking) { [weak self] _ in
            ServiceLocator.analytics.track(.orderDetailTrackingDeleteButtonTapped)
            self?.deleteTracking(tracking)
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = cell
        popoverController?.sourceRect = cell.bounds

        present(actionSheet, animated: true)
    }

    /// Sends the provided text to the general pasteboard and triggers a success haptic.
    ///
    func sendToPasteboard(_ text: String?, includeTrailingNewline: Bool = true) {
        guard var text = text, text.isEmpty == false else {
            return
        }

        if includeTrailingNewline {
            text += "\n"
        }

        UIPasteboard.general.string = text
        hapticGenerator.notificationOccurred(.success)
    }

    /// Opens details of the shipment tracking in a web view
    ///
    func openTrackingDetails(_ tracking: ShipmentTracking) {
        guard let trackingURL = tracking.trackingURL?.addHTTPSSchemeIfNecessary(),
              let url = URL(string: trackingURL) else {
            return
        }
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }

    /// Trigger view model to delete specified tracking and then reload data
    ///
    func deleteTracking(_ tracking: ShipmentTracking) {
        let order = viewModel.order
        viewModel.deleteTracking(tracking) { [weak self] error in
            if let _ = error {
                self?.displayDeleteErrorNotice(order: order, tracking: tracking)
                return
            }
            self?.tableView.reloadData()
        }
    }

    /// Displays the `Unable to delete tracking` Notice.
    ///
    func displayDeleteErrorNotice(order: Order, tracking: ShipmentTracking) {
        notices.displayDeleteErrorNotice(order: order, tracking: tracking) { [weak self] in
            self?.deleteTracking(tracking)
        }
    }

    /// Marks order complete and pop the view
    ///
    @objc func markOrderComplete() {
        markOrderCompleteHandler()
        // delay to let the above block take some time to execute
        // to avoid potential problems caused by deiniting the controller
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - Miscellanous
//
private extension ReviewOrderViewController {
    /// Some magic numbers for table view UI 🪄
    ///
    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
    }

    /// Localized copies
    ///
    enum Localization {
        static let screenTitle = NSLocalizedString("Review Order", comment: "Title of Review Order screen")
        static let productSectionTitle = NSLocalizedString("Product", comment: "Product section title in Review Order screen if there is one product.")
        static let productsSectionTitle = NSLocalizedString("Products",
                                                            comment: "Product section title in Review Order screen if there is more than one product.")
        static let customerSectionTitle = NSLocalizedString("Customer", comment: "Customer info section title in Review Order screen")
        static let trackingSectionTitle = NSLocalizedString("Tracking", comment: "Tracking section title in Review Order screen")
        static let customerNoteTitle = NSLocalizedString("Customer Provided Note", comment: "Customer note row title")
        static let shippingAddressTitle = NSLocalizedString("Shipping Address", comment: "Shipping Address title for customer info section")
        static let noAddressCellTitle = NSLocalizedString(
            "No address specified.",
            comment: "Order details > customer info > shipping details. This is where the address would normally display."
        )
        static let shippingMethodTitle = NSLocalizedString("Shipping Method", comment: "Shipping method title for customer info section")
        static let showBillingTitle = NSLocalizedString("View Billing Information",
                                                        comment: "Button on bottom of Customer's information to show the billing details")
        static let showBillingAccessibilityLabel = NSLocalizedString(
            "View Billing Information",
            comment: "Accessibility label for the 'View Billing Information' button"
        )
        static let showBillingAccessibilityHint = NSLocalizedString(
            "Show the billing details for this order.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to view billing information."
        )
        static let addTrackingTitle = NSLocalizedString("Add Tracking", comment: "Add Tracking row label")
        static let addTrackingAccessibilityHint = NSLocalizedString(
            "Adds tracking to an order.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to add tracking to an order. Should end with a period."
        )
        static let shippedTitle = NSLocalizedString("Shipped %@",
                                                    comment: "Date an item was shipped")
        static let notShippedYetTitle = NSLocalizedString("Not shipped yet",
                                                          comment: "Order details > tracking. " +
                          " This is where the shipping date would normally display.")
        static let emailMessage = NSLocalizedString(
            "The customer will receive an email once order is completed",
            comment: "Message at the bottom of Review Order screen to inform of emailing the customer upon completing order"
        )
        static let markOrderCompleteTitle = NSLocalizedString("Mark Order Complete", comment: "Action button on Review Order screen")
    }

    /// Localized copies for Shipment Tracking action
    ///
    enum TrackingAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the shipment tracking action sheet")
        static let copyTrackingNumber = NSLocalizedString("Copy Tracking Number", comment: "Copy tracking number button title")
        static let trackShipment = NSLocalizedString("Track Shipment", comment: "Track shipment button title")
        static let deleteTracking = NSLocalizedString("Delete Tracking", comment: "Delete tracking button title")
    }
}
