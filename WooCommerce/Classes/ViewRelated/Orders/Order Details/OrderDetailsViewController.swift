import UIKit
import Gridicons
import Contacts
import Yosemite
import SafariServices
import MessageUI
import Combine
import SwiftUI
import WooFoundation
import Experiments

// MARK: - OrderDetailsViewController: Displays the details for a given Order.
//
final class OrderDetailsViewController: UIViewController {

    /// Main Stack View, that contains all the other views of the screen
    ///
    @IBOutlet private weak var stackView: UIStackView!

    /// Main TableView.
    ///
    @IBOutlet private weak var tableView: UITableView!

    /// The top loader view, that will be embedded inside the stackview, on top of the tableview, while the screen is loading its
    /// content for the first time.
    ///
    private var topLoaderView: TopLoaderView = {
        let loaderView: TopLoaderView = TopLoaderView.instantiateFromNib()
        loaderView.setBody(Localization.Generic.topLoaderBannerDescription)
        return loaderView
    }()

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()

    /// Top banner that announces shipping labels features.
    ///
    private var topBannerView: TopBannerView?

    /// EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<Order> = {
        return EntityListener(storageManager: ServiceLocator.storageManager, readOnlyEntity: viewModel.order)
    }()

    /// Order to be rendered!
    ///
    private let viewModels: [OrderDetailsViewModel]

    private var viewModel: OrderDetailsViewModel {
        viewModels[currentIndex]
    }

    private let currentIndex: Int

    /// Callback closure when a different order is selected like from the quick navigation arrows.
    private let switchDetailsHandler: OrderListViewController.SelectOrderDetails

    // MARK: - View Lifecycle
    init(viewModels: [OrderDetailsViewModel], currentIndex: Int, switchDetailsHandler: @escaping OrderListViewController.SelectOrderDetails) {
        self.viewModels = viewModels
        self.currentIndex = currentIndex
        self.switchDetailsHandler = switchDetailsHandler
        super.init(nibName: Self.nibName, bundle: nil)
    }

    /// Used for screens that show order details always in a single-column view.
    convenience init(viewModel: OrderDetailsViewModel) {
        self.init(viewModels: [viewModel], currentIndex: 0, switchDetailsHandler: { _, _, _, _ in })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureTopLoaderView()
        configureTableView()
        configureStackView()
        registerTableViewCells()
        registerTableViewHeaderFooters()
        configureEntityListener()
        configureViewModel()
        updateTopBannerView()
        trackGiftCardsShown()
        trackShippingShown()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let waitingTracker = WaitingTimeTracker(trackScenario: .orderDetails)
        syncEverything { [weak self] in
            waitingTracker.end()

            self?.topLoaderView.isHidden = true

            /// We add the refresh control to the tableview just after the `topLoaderView` disappear for the first time.
            if self?.tableView.refreshControl == nil {
                self?.tableView.refreshControl = self?.refreshControl
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.updateHeaderHeight()
    }

    override var shouldShowOfflineBanner: Bool {
        true
    }
}

// MARK: - TableView Configuration
//
private extension OrderDetailsViewController {

    /// Setup: TopLoaderView
    func configureTopLoaderView() {
        stackView.insertArrangedSubview(topLoaderView, at: 0)
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension

        tableView.dataSource = viewModel.dataSource
        tableView.accessibilityIdentifier = "order-details-table-view"
    }

    func configureStackView() {
        stackView.layer.borderWidth = Constants.borderWidth
        stackView.layer.borderColor = UIColor.border.cgColor

        let maxWidthConstraint = stackView.widthAnchor.constraint(lessThanOrEqualToConstant: Constants.maxWidth)
        maxWidthConstraint.priority = .required
        NSLayoutConstraint.activate([maxWidthConstraint])
    }

    /// Setup: Navigation
    ///
    func configureNavigationBar() {
        // Title
        let titleFormat = NSLocalizedString("Order #%1$@", comment: "Order number title. Parameters: %1$@ - order number")
        title = String.localizedStringWithFormat(titleFormat, viewModel.order.number)

        let editButton = UIBarButtonItem(title: Localization.NavBar.editOrder,
                                         style: .plain,
                                         target: self,
                                         action: #selector(editOrder))
        editButton.accessibilityIdentifier = "order-details-edit-button"
        editButton.isEnabled = viewModel.editButtonIsEnabled
        navigationItem.rightBarButtonItems = [editButton] + orderNavigationRightBarButtonItems()

        navigationItem.largeTitleDisplayMode = .never
    }

    func orderNavigationRightBarButtonItems() -> [UIBarButtonItem] {
        guard viewModels.count > 1 else { return [] }

        let upArrowButon = UIBarButtonItem(
            image: UIImage(systemName: "chevron.up"),
            style: .plain,
            target: self,
            action: #selector(loadPreviousOrder)
        )

        // The buttons are too far apart when setting them to rightBarButtonItems, let's adjust the inset to provide better visuals
        upArrowButon.imageInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        upArrowButon.isEnabled = viewModels[safe: currentIndex - 1] != nil

        let downArrowButon = UIBarButtonItem(
            image: UIImage(systemName: "chevron.down"),
            style: .plain,
            target: self,
            action: #selector(loadNextOrder)
        )

        downArrowButon.isEnabled = viewModels[safe: currentIndex + 1] != nil

        return [downArrowButon, upArrowButon]
    }

    @objc func loadPreviousOrder() {
        loadOrder(with: currentIndex - 1)
    }

    @objc func loadNextOrder() {
        loadOrder(with: currentIndex + 1)
    }

    func loadOrder(with index: Int) {
        switchDetailsHandler(viewModels, index, true, nil)
    }

    /// Setup: EntityListener
    ///
    func configureEntityListener() {
        entityListener.onUpsert = { [weak self] order in
            guard let self = self else {
                return
            }
            self.viewModel.update(order: order)
            self.reloadTableViewSectionsAndData()
        }
    }

    private func configureViewModel() {
        viewModel.onUIReloadRequired = { [weak self] in
            self?.reloadTableViewDataIfPossible()
        }

        viewModel.configureResultsControllers { [weak self] in
            self?.reloadTableViewSectionsAndData()
        }

        viewModel.onCellAction = { [weak self] (actionType, indexPath) in
            self?.handleCellAction(actionType, at: indexPath)
        }

        viewModel.onShippingLabelMoreMenuTapped = { [weak self] shippingLabel, sourceView in
            self?.shippingLabelMoreMenuTapped(shippingLabel: shippingLabel, sourceView: sourceView)
        }

        viewModel.onProductsMoreMenuTapped = { [weak self] sourceView in
            self?.productsMoreMenuTapped(sourceView: sourceView)
        }
    }

    /// Reloads the tableView's data, assuming the view has been loaded.
    ///
    func reloadTableViewDataIfPossible() {
        guard isViewLoaded else {
            return
        }

        tableView.reloadData()

        updateTopBannerView()
    }

    /// Reloads the tableView's sections and data.
    ///
    func reloadTableViewSectionsAndData() {
        configureNavigationBar()
        reloadSections()
        reloadTableViewDataIfPossible()
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        viewModel.registerTableViewCells(tableView)
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters() {
        viewModel.registerTableViewHeaderFooters(tableView)
    }
}


// MARK: - Sections
//
private extension OrderDetailsViewController {

    func reloadSections() {
        viewModel.reloadSections()
    }
}


// MARK: - Notices
//
private extension OrderDetailsViewController {

    /// Displays the `Unable to delete tracking` Notice.
    ///
    func displayDeleteErrorNotice(order: Order, tracking: ShipmentTracking) {
        OrderDetailsNotices.shared.displayDeleteTrackingErrorNotice(order: order, tracking: tracking) { [weak self] in
            self?.deleteTracking(tracking)
        }
    }

    /// Displays the `Unable to trash order` Notice.
    ///
    func displayTrashOrderErrorNotice(order: Order) {
        OrderDetailsNotices.shared.displayTrashOrderErrorNotice(order: order) {
            [weak self] in
            self?.trashOrderAction()
        }
    }

    /// Enqueues the `Order Trash` Notice. Whenever the `Undo` button gets pressed, we'll execute the `onUndoAction` closure.
    ///
    private static func displayOrderTrashUndoNotice(order: Order, onUndoAction: @escaping () -> Void) {
        let notice = Notice(title: Localization.Notice.orderTrashUndoMessage,
                            feedbackType: .success,
                            actionTitle: Localization.Notice.orderTrashActionTitle,
                            actionHandler: onUndoAction)

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}

// MARK: - Top Banner
//
private extension OrderDetailsViewController {
    func updateTopBannerView() {
        let factory = ShippingLabelsTopBannerFactory(shouldShowShippingLabelCreation: viewModel.dataSource.shouldShowShippingLabelCreation,
                                                     shippingLabels: viewModel.dataSource.shippingLabels)
        let isExpanded = topBannerView?.isExpanded ?? false
        factory.createTopBannerIfNeeded(isExpanded: isExpanded,
                                        expandedStateChangeHandler: { [weak self] in
                                            self?.tableView.updateHeaderHeight()
                                        }, onGiveFeedbackButtonPressed: { [weak self] in
                                            self?.presentShippingLabelsFeedbackSurvey()
                                        }, onDismissButtonPressed: { [weak self] in
                                            self?.dismissTopBanner()
                                        }, onCompletion: { [weak self] topBannerView in
                                            if let topBannerView = topBannerView {
                                                self?.showTopBannerView(topBannerView)
                                            } else {
                                                self?.hideTopBannerView()
                                            }
                                        })
    }

    func showTopBannerView(_ topBannerView: TopBannerView) {
        guard tableView.tableHeaderView == nil else {
            return
        }

        self.topBannerView = topBannerView
        // A frame-based container view is needed for table view's `tableHeaderView` and its height is recalculated in `viewDidLayoutSubviews`, so that the
        // top banner view can be Auto Layout based with dynamic height.
        let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.width), height: Int(Constants.headerDefaultHeight)))
        headerContainer.addSubview(topBannerView)
        headerContainer.pinSubviewToAllEdges(topBannerView, insets: Constants.headerContainerInsets)
        tableView.tableHeaderView = headerContainer
        tableView.updateHeaderHeight()
    }

    func hideTopBannerView() {
        guard tableView.tableHeaderView != nil else {
            return
        }

        topBannerView?.removeFromSuperview()
        topBannerView = nil
        tableView.tableHeaderView = nil
        tableView.updateHeaderHeight()
    }

    func presentShippingLabelsFeedbackSurvey() {
        let navigationController = SurveyCoordinatingController(survey: .shippingLabelsRelease3Feedback)
        present(navigationController, animated: true, completion: nil)
    }

    func dismissTopBanner() {
        hideTopBannerView()
    }
}

// MARK: - Action Handlers
//
private extension OrderDetailsViewController {

    @objc func pullToRefresh() {
        ServiceLocator.analytics.track(.orderDetailPulledToRefresh)
        refreshControl.beginRefreshing()
        syncEverything { [weak self] in
            NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)
            self?.refreshControl.endRefreshing()
        }
    }

    /// Presents the order edit form
    ///
    @objc private func editOrder() {
        let viewModel = EditableOrderViewModel(siteID: viewModel.order.siteID, flow: .editing(initialOrder: viewModel.order))
        let viewController = OrderFormHostingController(viewModel: viewModel)
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sideBySideViewForOrderForm) {
            viewController.modalPresentationStyle = .overFullScreen
            present(viewController, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: viewController)
            present(navController, animated: true)
        }

        let hasMultipleShippingLines = self.viewModel.order.shippingLines.count > 1
        let hasMultipleFeeLines = self.viewModel.order.fees.count > 1
        ServiceLocator.analytics.track(event: WooAnalyticsEvent.Orders.orderEditButtonTapped(hasMultipleShippingLines: hasMultipleShippingLines,
                                                                                             hasMultipleFeeLines: hasMultipleFeeLines))
    }
}


// MARK: - Sync'ing Helpers
//
private extension OrderDetailsViewController {

    /// Syncs all data related to the current order.
    ///
    func syncEverything(onCompletion: (() -> ())? = nil) {
        viewModel.syncEverything(onReloadSections: { [weak self] in
            self?.reloadTableViewSectionsAndData()
        }, onCompletion: onCompletion)
    }

    func deleteTracking(_ tracking: ShipmentTracking) {
        let order = viewModel.order
        viewModel.deleteTracking(tracking) { [weak self] error in
            if let _ = error {
                self?.displayDeleteErrorNotice(order: order, tracking: tracking)
                return
            }

            self?.reloadSections()
        }
    }
}

// MARK: - Actions
//
private extension OrderDetailsViewController {

    func handleCellAction(_ type: OrderDetailsDataSource.CellActionType, at indexPath: IndexPath?) {
        switch type {
        case .markComplete:
            markOrderCompleteWasPressed()
        case .summary:
            displayOrderStatusList()
        case .tracking:
            guard let indexPath = indexPath else {
                break
            }
            trackingWasPressed(at: indexPath)
        case .issueRefund:
            issueRefundWasPressed()
        case .collectPayment:
            guard indexPath != nil else {
                break
            }
            collectPaymentTapped()
        case .reprintShippingLabel(let shippingLabel):
            let printNavigationController = WooNavigationController()
            let coordinator = PrintShippingLabelCoordinator(shippingLabels: [shippingLabel],
                                                            printType: .reprint,
                                                            sourceNavigationController: printNavigationController)
            let printViewController = coordinator.createPrintViewController()
            printNavigationController.viewControllers = [printViewController]
            present(printNavigationController, animated: true)
        case .createShippingLabel:
            navigateToCreateShippingLabelForm()
        case .shippingLabelTrackingMenu(let shippingLabel, let sourceView):
            shippingLabelTrackingMoreMenuTapped(shippingLabel: shippingLabel, sourceView: sourceView)
        case let .viewAddOns(addOns):
            itemAddOnsButtonTapped(addOns: addOns)
        case .editCustomerNote:
            editCustomerNoteTapped()
        case .editShippingAddress:
            editShippingAddressTapped()
        case .trashOrder:
            trashOrderTapped()
        }
    }

    func navigateToCreateShippingLabelForm() {
        guard viewModel.dataSource.isEligibleForWooShipping else {
            // Navigate to legacy shipping label creation form if Woo Shipping extension is not supported.
            let shippingLabelFormVC = ShippingLabelFormViewController(order: viewModel.order)
            shippingLabelFormVC.onLabelPurchase = { [weak self] isOrderComplete in
                if isOrderComplete {
                    self?.markOrderCompleteFromShippingLabels()
                }
            }
            shippingLabelFormVC.onLabelSave = { [weak self] in
                guard let self = self, let navigationController = self.navigationController, navigationController.viewControllers.contains(self) else {
                    // Navigate back to order details when presented from push notification
                    if let orderLoaderVC = self?.parent as? OrderLoaderViewController {
                        self?.navigationController?.popToViewController(orderLoaderVC, animated: true)
                    }
                    return
                }
                syncEverything()
                self.dismiss(animated: true)
            }
            shippingLabelFormVC.onCancel = { [weak self] in
                self?.dismiss(animated: true)
            }

            let shippingLabelNavigationController = WooNavigationController(rootViewController: shippingLabelFormVC)
            navigationController?.present(shippingLabelNavigationController, animated: true)
            return
        }

        let shippingLabelCreationVM = WooShippingCreateLabelsViewModel(order: viewModel.order, onLabelPurchase: { [weak self] markOrderComplete in
            if markOrderComplete {
                self?.markOrderCompleteFromShippingLabels()
            }
        })
        let shippingLabelCreationVC = WooShippingCreateLabelsViewHostingController(viewModel: shippingLabelCreationVM)
        shippingLabelCreationVC.modalPresentationStyle = .overFullScreen
        navigationController?.present(shippingLabelCreationVC, animated: true)
    }

    func markOrderCompleteWasPressed() {
        ServiceLocator.analytics.track(.orderFulfillmentCompleteButtonTapped)
        let reviewOrderViewModel = ReviewOrderViewModel(order: viewModel.order, products: viewModel.products, showAddOns: viewModel.dataSource.showAddOns)
        let controller = ReviewOrderViewController(viewModel: reviewOrderViewModel) { [weak self] in
            guard let self = self else { return }
            let fulfillmentProcess = self.viewModel.markCompleted(flow: .editing)
            let presenter = OrderFulfillmentNoticePresenter()
            presenter.present(process: fulfillmentProcess)
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    func markOrderCompleteFromShippingLabels() {
        let fulfillmentProcess = self.viewModel.markCompleted(flow: .editing)

        var cancellables = Set<AnyCancellable>()
        var cancellable: AnyCancellable = AnyCancellable { }
        cancellable = fulfillmentProcess.result.sink { completion in
            if case .failure = completion {
                ServiceLocator.analytics.track(.shippingLabelOrderFulfillFailed)
            }
            else {
                ServiceLocator.analytics.track(.shippingLabelOrderFulfillSucceeded)
            }
            cancellables.remove(cancellable)
        } receiveValue: {
            // Noop. There is no value to receive or act on.
        }

        // Insert in `cancellables` to keep the `sink` handler active.
        cancellables.insert(cancellable)
    }

    func trackingWasPressed(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? OrderTrackingTableViewCell else {
            return
        }

        displayShipmentTrackingAlert(from: cell, indexPath: indexPath)
    }

    func openTrackingDetails(_ tracking: ShipmentTracking) {
        guard let trackingURL = tracking.trackingURL?.addHTTPSSchemeIfNecessary(),
            let url = URL(string: trackingURL) else {
            return
        }

        ServiceLocator.analytics.track(.orderDetailTrackPackageButtonTapped)
        displayWebView(url: url)
    }

    func issueRefundWasPressed() {
        let issueRefundCoordinatingController = IssueRefundCoordinatingController(order: viewModel.order, refunds: viewModel.refunds)
        present(issueRefundCoordinatingController, animated: true)
    }

    func displayWebView(url: URL) {
        WebviewHelper.launch(url, with: self)
    }

    func productsMoreMenuTapped(sourceView: UIView) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        actionSheet.addCancelActionWithTitle(Localization.ProductsMoreMenu.cancelAction)
        actionSheet.addDefaultActionWithTitle(Localization.ProductsMoreMenu.createShippingLabelAction) { [weak self] _ in
            self?.navigateToCreateShippingLabelForm()
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = sourceView

        present(actionSheet, animated: true)
    }

    func shippingLabelMoreMenuTapped(shippingLabel: ShippingLabel, sourceView: UIView) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        actionSheet.addCancelActionWithTitle(Localization.ShippingLabelMoreMenu.cancelAction)

        actionSheet.addDefaultActionWithTitle(Localization.ShippingLabelMoreMenu.requestRefundAction) { [weak self] _ in
            let refundViewController = RefundShippingLabelViewController(shippingLabel: shippingLabel) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            // Disables the bottom bar (tab bar) when requesting a refund.
            refundViewController.hidesBottomBarWhenPushed = true
            self?.show(refundViewController, sender: self)
        }

        if let url = shippingLabel.commercialInvoiceURL, url.isNotEmpty {
            actionSheet.addDefaultActionWithTitle(Localization.ShippingLabelMoreMenu.printCustomsFormAction) { [weak self] _ in
                let printCustomsFormsView = PrintCustomsFormsView(invoiceURLs: [url])
                let hostingController = UIHostingController(rootView: printCustomsFormsView)
                hostingController.hidesBottomBarWhenPushed = true
                self?.show(hostingController, sender: self)
            }
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = sourceView

        present(actionSheet, animated: true)
    }

    func shippingLabelTrackingMoreMenuTapped(shippingLabel: ShippingLabel, sourceView: UIView) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        actionSheet.addCancelActionWithTitle(Localization.ShippingLabelTrackingMoreMenu.cancelAction)

        actionSheet.addDefaultActionWithTitle(Localization.ShippingLabelTrackingMoreMenu.copyTrackingNumberAction) { _ in
            ServiceLocator.analytics.track(event: .shipmentTrackingMenu(action: .copy))
            shippingLabel.trackingNumber.sendToPasteboard(includeTrailingNewline: false)
        }

        // Only shows the tracking action when there is a tracking URL.
        if let url = ShippingLabelTrackingURLGenerator.url(for: shippingLabel) {
            actionSheet.addDefaultActionWithTitle(Localization.ShippingLabelTrackingMoreMenu.trackShipmentAction) { [weak self] _ in
                guard let self = self else { return }
                ServiceLocator.analytics.track(event: .shipmentTrackingMenu(action: .track))
                WebviewHelper.launch(url, with: self)
            }
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = sourceView

        present(actionSheet, animated: true)
    }

    func editCustomerNoteTapped() {
        let editNoteViewController = EditCustomerNoteHostingController(viewModel: viewModel.editNoteViewModel)
        present(editNoteViewController, animated: true)

        ServiceLocator.analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowStarted(subject: .customerNote))
    }

    func editShippingAddressTapped() {
        let viewModel = EditOrderAddressFormViewModel(order: viewModel.order, type: .shipping)
        let editAddressViewController = EditOrderAddressHostingController(viewModel: viewModel)
        let navigationController = WooNavigationController(rootViewController: editAddressViewController)
        present(navigationController, animated: true, completion: nil)
    }

    func trashOrderTapped() {
        ServiceLocator.analytics.track(.orderDetailTrashButtonTapped)

        let alertController = UIAlertController(title: Localization.Alert.orderTrashConfirmationTitle,
                                                message: Localization.Alert.orderTrashConfirmationMessage,
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: Localization.Alert.orderTrashConfirmationCancelButton,
                                   style: .cancel) { (action) in
        }
        let confirm = UIAlertAction(title: Localization.Alert.orderTrashConfirmationConfirmButton,
                                    style: .default) { [weak self] (action) in
            self?.trashOrderAction()
        }
        alertController.addAction(cancel)
        alertController.addAction(confirm)
        present(alertController, animated: true)
    }

    func trashOrderAction() {
        let viewModel = viewModel
        let order = viewModel.order
        viewModel.trashOrder { [weak self] result in
            switch result {
            case .success(let order):
                NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)
                OrderDetailsViewController.displayOrderTrashUndoNotice(order: order) {
                    OrderDetailsViewController.undoTrashOrderAction(viewModel: viewModel, order: order)
                }

                // Navigate back to the master view controller of the split view controller to display the order list.
                if let splitViewController = self?.splitViewController,
                    let navigationController = splitViewController.viewControllers.last as? UINavigationController {
                    DispatchQueue.main.async {
                        navigationController.popToRootViewController(animated: true)
                    }
                }
            case .failure(let error):
                self?.displayTrashOrderErrorNotice(order: order)
                DDLogError("⛔️ Order Trash Failure: [Order ID: \(order.orderID)]. Error: \(error)")
            }
        }
    }

    // It's possible to restore an order from the trash by simply resetting its status to the previous value it held.
    static func undoTrashOrderAction(viewModel: OrderDetailsViewModel, order: Order) {
        let undoStatus = order.status
        let undo = updateOrderStatusAction(viewModel: viewModel, siteID: order.siteID, orderID: order.orderID, status: undoStatus)

        ServiceLocator.stores.dispatch(undo)
    }

    @objc private func collectPaymentTapped() {
        collectPayment()

        // Track tapped event
        ServiceLocator.analytics.track(event: WooAnalyticsEvent.Orders.collectPaymentTapped(flow: .orderDetails))
    }

    private func collectPayment() {
        let paymentMethodsViewController = PaymentMethodsHostingController(viewModel: viewModel.paymentMethodsViewModel)
        paymentMethodsViewController.parentController = self
        present(paymentMethodsViewController, animated: true)
    }

    private func itemAddOnsButtonTapped(addOns: [OrderItemProductAddOn]) {
        let addOnsViewModel = OrderAddOnListI1ViewModel(addOns: addOns)
        let addOnsController = OrderAddOnsListViewController(viewModel: addOnsViewModel)
        let navigationController = WooNavigationController(rootViewController: addOnsController)
        present(navigationController, animated: true, completion: nil)
    }

    /// Tracks when the Gift Cards section will be shown.
    ///
    func trackGiftCardsShown() {
        guard viewModel.dataSource.shouldShowGiftCards else {
            return
        }
        ServiceLocator.analytics.track(event: .Orders.giftCardsShown())
    }

    /// Tracks when the Shipping section will be shown.
    ///
    func trackShippingShown() {
        let shippingLinesCount = viewModel.dataSource.order.shippingLines.count
        guard shippingLinesCount > 0 else {
            return
        }
        ServiceLocator.analytics.track(event: .Orders.shippingShown(shippingLinesCount: Int64(shippingLinesCount)))
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension OrderDetailsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.tableView(tableView, in: self, didSelectRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard viewModel.dataSource.checkIfCopyingIsAllowed(for: indexPath) else {
            // Only allow the leading swipe action on the address rows
            return UISwipeActionsConfiguration(actions: [])
        }

        let copyActionTitle = NSLocalizedString("Copy", comment: "Copy address text button title — should be one word and as short as possible.")
        let copyAction = UIContextualAction(style: .normal, title: copyActionTitle) { [weak self] (action, view, success) in
            self?.viewModel.dataSource.copyText(at: indexPath)
            success(true)
        }
        copyAction.backgroundColor = .primary

        return UISwipeActionsConfiguration(actions: [copyAction])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // No trailing action on any cell
        return UISwipeActionsConfiguration(actions: [])
    }

    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return viewModel.dataSource.checkIfCopyingIsAllowed(for: indexPath)
    }

    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        guard action == #selector(copy(_:)) else {
            return
        }

        viewModel.dataSource.copyText(at: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Remove the first header
        if section == 0 {
            return CGFloat.leastNormalMagnitude
        }

        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return viewModel.dataSource.viewForHeaderInSection(section, tableView: tableView)
    }
}

// MARK: - Trackings alert
// Track / delete tracking alert
private extension OrderDetailsViewController {
    /// Displays an alert that offers deleting a shipment tracking or opening
    /// it in a webview
    ///

    func displayShipmentTrackingAlert(from sourceView: UIView, indexPath: IndexPath) {
        guard let tracking = viewModel.dataSource.orderTracking(at: indexPath) else {
            return
        }

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        actionSheet.addCancelActionWithTitle(TrackingAction.dismiss)

        actionSheet.addDefaultActionWithTitle(TrackingAction.copyTrackingNumber) { [weak self] _ in
            self?.viewModel.dataSource.copyText(at: indexPath)
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
        popoverController?.sourceView = sourceView
        popoverController?.sourceRect = sourceView.bounds

        present(actionSheet, animated: true)
    }
}


// MARK: - Order Status List Child View
//
private extension OrderDetailsViewController {
    private func displayOrderStatusList() {
        ServiceLocator.analytics.track(.orderDetailOrderStatusEditButtonTapped,
                                       withProperties: ["status": viewModel.order.status.rawValue])

        let statusListViewModel = OrderStatusListViewModel(siteID: viewModel.order.siteID,
                                                           status: viewModel.order.status)
        let statusList = OrderStatusListViewController(viewModel: statusListViewModel)

        statusListViewModel.didCancelSelection = { [weak statusList] in
            statusList?.dismiss(animated: true, completion: nil)
        }

        let viewModel = self.viewModel

        statusListViewModel.didApplySelection = { [weak statusList] (selectedStatus) in
            statusList?.dismiss(animated: true) {
                OrderDetailsViewController.setOrderStatus(to: selectedStatus, viewModel: viewModel)
            }
        }

        let navigationController = WooNavigationController(rootViewController: statusList)

        present(navigationController, animated: true)
    }

    static func setOrderStatus(to newStatus: OrderStatusEnum, viewModel: OrderDetailsViewModel) {
        let orderID = viewModel.order.orderID
        let undoStatus = viewModel.order.status
        let done = updateOrderStatusAction(viewModel: viewModel,
                                           siteID: viewModel.order.siteID,
                                           orderID: viewModel.order.orderID,
                                           status: newStatus)
        let undo = updateOrderStatusAction(viewModel: viewModel,
                                           siteID: viewModel.order.siteID,
                                           orderID: viewModel.order.orderID,
                                           status: undoStatus)

        ServiceLocator.stores.dispatch(done)
        ServiceLocator.analytics.track(event: WooAnalyticsEvent.Orders.orderStatusChange(flow: .editing, orderID: orderID, from: undoStatus, to: newStatus))

        displayOrderStatusUpdatedNotice {
            ServiceLocator.stores.dispatch(undo)
            ServiceLocator.analytics.track(event: WooAnalyticsEvent.Orders.orderStatusChange(flow: .editing, orderID: orderID, from: newStatus, to: undoStatus))
        }
    }

    /// Returns an Order Update Action that will result in the specified Order Status updated accordingly.
    ///
    private static func updateOrderStatusAction(viewModel: OrderDetailsViewModel, siteID: Int64, orderID: Int64, status: OrderStatusEnum) -> Action {
        return OrderAction.updateOrderStatus(siteID: siteID, orderID: orderID, status: status, onCompletion: { error in
            guard let error = error else {
                NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)
                viewModel.syncNotes()
                ServiceLocator.analytics.track(.orderStatusChangeSuccess)
                return
            }

            ServiceLocator.analytics.track(.orderStatusChangeFailed, withError: error)
            DDLogError("⛔️ Order Update Failure: [\(orderID).status = \(status)]. Error: \(error)")

            OrderDetailsViewController.displayOrderStatusErrorNotice(viewModel: viewModel, orderID: orderID, status: status)
        })
    }

    /// Enqueues the `Order Updated` Notice. Whenever the `Undo` button gets pressed, we'll execute the `onUndoAction` closure.
    ///
    private static func displayOrderStatusUpdatedNotice(onUndoAction: @escaping () -> Void) {
        let message = NSLocalizedString("Order status updated", comment: "Order status update success notice")
        let actionTitle = NSLocalizedString("Undo", comment: "Undo Action")
        let notice = Notice(title: message, feedbackType: .success, actionTitle: actionTitle, actionHandler: onUndoAction)

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Enqueues the `Unable to Change Status of Order` Notice.
    ///
    private static func displayOrderStatusErrorNotice(viewModel: OrderDetailsViewModel, orderID: Int64, status: OrderStatusEnum) {
        let titleFormat = NSLocalizedString(
            "Unable to change status of order #%1$d",
            comment: "Content of error presented when updating the status of an Order fails. "
            + "It reads: Unable to change status of order #{order number}. "
            + "Parameters: %1$d - order number"
        )
        let title = String.localizedStringWithFormat(titleFormat, orderID)
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: title, message: nil, feedbackType: .error, actionTitle: actionTitle) {
            OrderDetailsViewController.setOrderStatus(to: status, viewModel: viewModel)
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}


// MARK: - Constants
//
private extension OrderDetailsViewController {

    enum TrackingAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the shipment tracking action sheet")
        static let copyTrackingNumber = NSLocalizedString("Copy Tracking Number", comment: "Copy tracking number button title")
        static let trackShipment = NSLocalizedString("Track Shipment", comment: "Track shipment button title")
        static let deleteTracking = NSLocalizedString("Delete Tracking", comment: "Delete tracking button title")
    }

    enum Localization {
        enum Generic {
            static let topLoaderBannerDescription = NSLocalizedString("Loading content",
                                                                      comment: "Text of the loading banner in Order Detail when loaded for the first time")
        }

        enum NavBar {
            static let editOrder = NSLocalizedString("Edit", comment: "Button to edit an order on Order Details screen")
        }

        enum ProductsMoreMenu {
            static let cancelAction = NSLocalizedString("Cancel", comment: "Cancel the more menu action sheet on Products section")
            static let createShippingLabelAction = NSLocalizedString("Create Shipping Label",
                                                                     comment: "Option to create new shipping label from the action " +
                                                                     "sheet on Products section of Order Details screen")
        }

        enum ShippingLabelMoreMenu {
            static let cancelAction = NSLocalizedString("Cancel", comment: "Cancel the shipping label more menu action sheet")
            static let requestRefundAction = NSLocalizedString("Request a Refund",
                                                               comment: "Request a refund on a shipping label from the shipping label more menu action sheet")
            static let printCustomsFormAction = NSLocalizedString("Print Customs Form",
                                                                  comment: "Print the customs form for the shipping label" +
                                                                    " from the shipping label more menu action sheet")
        }

        enum ShippingLabelTrackingMoreMenu {
            static let cancelAction = NSLocalizedString("Cancel", comment: "Cancel the shipping label tracking more menu action sheet")
            static let copyTrackingNumberAction =
                NSLocalizedString("Copy tracking number",
                                  comment: "Copy tracking number of a shipping label from the shipping label tracking more menu action sheet")
            static let trackShipmentAction =
                NSLocalizedString("Track shipment",
                                  comment: "Track shipment of a shipping label from the shipping label tracking more menu action sheet")
        }

        enum ActionsMenu {
            static let accessibilityLabel = NSLocalizedString("Order actions", comment: "Accessibility label for button triggering more actions menu sheet.")
            static let cancelAction = NSLocalizedString("Cancel", comment: "Cancel the main more actions menu sheet.")
        }

        enum Alert {
            static let orderTrashConfirmationTitle = NSLocalizedString("OrderDetail.trashOrder.alert.title",
                                                                       value: "Remove order",
                                                                       comment: "Title of the alert when a user is moving an order to the trash")
            static let orderTrashConfirmationMessage = NSLocalizedString("OrderDetail.trashOrder.alert.message",
                                                                         value: "Do you want to move this order to the Trash?",
                                                                         comment: "Body of the alert when a user is moving an order to the trash")
            static let orderTrashConfirmationCancelButton =
            NSLocalizedString("OrderDetail.trashOrder.alert.cancelButton",
                              value: "Cancel",
                              comment: "Cancel button on the alert when the user is cancelling the action on moving an order to the trash")
            static let orderTrashConfirmationConfirmButton =
            NSLocalizedString("OrderDetail.trashOrder.alert.moveToTrashButton",
                              value: "Move to Trash",
                              comment: "Confirmation button on the alert when the user is moving an order to the trash")
        }

        enum Notice {
            static let orderTrashUndoMessage = NSLocalizedString("OrderDetail.trashOrder.notice.undoMessage",
                                                          value: "Order trashed",
                                                          comment: "Order trashed success notice")
            static let orderTrashActionTitle = NSLocalizedString("OrderDetail.trashOrder.notice.undoAction",
                                                          value: "Undo",
                                                          comment: "Undo Action")
        }
    }

    enum Constants {
        static let headerDefaultHeight = CGFloat(130)
        static let headerContainerInsets = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
        static let maxWidth = CGFloat(525)
        static let borderWidth = CGFloat(0.5)
    }

    /// Mailing a receipt failed but the SDK didn't return a more specific error
    ///
    struct UnknownEmailError: Error {}
}
