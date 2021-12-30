import UIKit
import Gridicons
import Contacts
import Yosemite
import SafariServices
import MessageUI
import Combine
import SwiftUI

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
    var viewModel: OrderDetailsViewModel! {
        didSet {
            reloadTableViewSectionsAndData()
        }
    }

    private let notices = OrderDetailsNotices()

    /// Orchestrates what needs to be presented in the modal views
    /// that provide user-facing feedback about the card present payment process.
    private lazy var paymentAlerts: OrderDetailsPaymentAlerts = {
        OrderDetailsPaymentAlerts(presentingController: self)
    }()

    /// Subscription that listens for connected readers while we are trying to connect to one to capture payment
    /// We need to cancel that subscription if the process is canceled by the user or when we connect to a reader.
    ///
    private var cardReaderAvailableSubscription: Combine.Cancellable? = nil

    /// Connection Controller (helps connect readers)
    ///
    private lazy var connectionController: CardReaderConnectionController? = {
        guard let siteID = viewModel?.order.siteID else {
            return nil
        }

        return CardReaderConnectionController(
            forSiteID: siteID,
            knownReaderProvider: CardReaderSettingsKnownReaderStorage(),
            alertsProvider: CardReaderSettingsAlerts()
        )
    }()

    // MARK: - View Lifecycle

    /// Create an instance of `Self` from its corresponding storyboard.
    ///
    static func instantiatedViewControllerFromStoryboard() -> Self? {
        let storyboard = UIStoryboard.orders
        let identifier = "OrderDetailsViewController"
        return storyboard.instantiateViewController(withIdentifier: identifier) as? Self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTopLoaderView()
        configureTableView()
        registerTableViewCells()
        registerTableViewHeaderFooters()
        configureEntityListener()
        configureViewModel()
        updateTopBannerView()

        // FIXME: this is a hack. https://github.com/woocommerce/woocommerce-ios/issues/1779
        reloadTableViewSectionsAndData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncEverything { [weak self] in
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
        return true
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
    }

    /// Setup: Navigation
    ///
    func configureNavigation() {
        let titleFormat = NSLocalizedString("Order #%1$@", comment: "Order number title. Parameters: %1$@ - order number")
        title = String.localizedStringWithFormat(titleFormat, viewModel.order.number)
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
        notices.displayDeleteErrorNotice(order: order, tracking: tracking) { [weak self] in
            self?.deleteTracking(tracking)
        }
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
}


// MARK: - Sync'ing Helpers
//
private extension OrderDetailsViewController {
    func syncEverything(onCompletion: (() -> ())? = nil) {
        let group = DispatchGroup()

        group.enter()
        syncOrder { _ in
            group.leave()
        }

        group.enter()
        syncProducts { _ in
            group.leave()
        }

        group.enter()
        syncProductVariations { _ in
            group.leave()
        }

        group.enter()
        syncRefunds() { _ in
            group.leave()
        }

        group.enter()
        syncShippingLabels() { _ in
            group.leave()
        }

        group.enter()
        syncNotes { _ in
            group.leave()
        }

        group.enter()
        syncTrackingsEnablingAddButtonIfReachable {
            group.leave()
        }

        group.enter()
        checkShippingLabelCreationEligibility {
            group.leave()
        }

        group.enter()
        refreshCardPresentPaymentEligibility()
        group.leave()

        group.enter()
        syncSavedReceipts {_ in
            group.leave()
        }

        group.enter()
        checkOrderAddOnFeatureSwitchState {
            group.leave()
        }

        group.notify(queue: .main) {
            onCompletion?()
        }
    }

    func syncOrder(onCompletion: ((Error?) -> ())? = nil) {
        viewModel.syncOrder { [weak self] (order, error) in
            guard let self = self, let order = order else {
                onCompletion?(error)
                return
            }

            self.viewModel.update(order: order)

            onCompletion?(nil)
        }
    }

    func syncTracking(onCompletion: ((Error?) -> Void)? = nil) {
        viewModel.syncTracking(onCompletion: onCompletion)
    }

    func syncNotes(onCompletion: ((Error?) -> ())? = nil) {
        viewModel.syncNotes(onCompletion: onCompletion)
    }

    func syncProducts(onCompletion: ((Error?) -> ())? = nil) {
        viewModel.syncProducts(onCompletion: onCompletion)
    }

    func syncProductVariations(onCompletion: ((Error?) -> ())? = nil) {
        viewModel.syncProductVariations(onCompletion: onCompletion)
    }

    func syncRefunds(onCompletion: ((Error?) -> ())? = nil) {
        viewModel.syncRefunds(onCompletion: onCompletion)
    }

    func syncShippingLabels(onCompletion: ((Error?) -> ())? = nil) {
        viewModel.syncShippingLabels(onCompletion: onCompletion)
    }

    func syncSavedReceipts(onCompletion: ((Error?) -> ())? = nil) {
        viewModel.syncSavedReceipts(onCompletion: onCompletion)
    }

    func syncTrackingsEnablingAddButtonIfReachable(onCompletion: (() -> Void)? = nil) {
        syncTracking { [weak self] error in
            if error == nil {
                self?.viewModel.trackingIsReachable = true
            }

            self?.reloadTableViewSectionsAndData()
            onCompletion?()
        }
    }

    func checkShippingLabelCreationEligibility(onCompletion: (() -> Void)? = nil) {
        viewModel.checkShippingLabelCreationEligibility { [weak self] in
            self?.reloadTableViewSectionsAndData()
            onCompletion?()
        }
    }

    func refreshCardPresentPaymentEligibility() {
        viewModel.refreshCardPresentPaymentEligibility()
    }

    func checkOrderAddOnFeatureSwitchState(onCompletion: (() -> Void)? = nil) {
        viewModel.checkOrderAddOnFeatureSwitchState { [weak self] in
            self?.reloadTableViewSectionsAndData()
            onCompletion?()
        }
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

    func syncOrderAfterPaymentCollection(onCompletion: @escaping ()-> Void) {
        let group = DispatchGroup()

        group.enter()
        syncOrder { _ in
            group.leave()
        }

        group.enter()
        syncNotes { _ in
            group.leave()
        }

        group.enter()
        syncSavedReceipts { _ in
            group.leave()
        }

        group.notify(queue: .main) {
            NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)
            onCompletion()
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
            guard let indexPath = indexPath else {
                break
            }
            collectPayment(at: indexPath)
        case .reprintShippingLabel(let shippingLabel):
            guard let navigationController = navigationController else {
                assertionFailure("Cannot reprint a shipping label because `navigationController` is nil")
                return
            }
            let coordinator = PrintShippingLabelCoordinator(shippingLabels: [shippingLabel],
                                                            printType: .reprint,
                                                            sourceNavigationController: navigationController)
            coordinator.showPrintUI()
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
        }
    }

    func navigateToCreateShippingLabelForm() {
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

            navigationController.popToViewController(self, animated: true)
        }
        shippingLabelFormVC.hidesBottomBarWhenPushed = true
        navigationController?.show(shippingLabelFormVC, sender: self)
    }

    func markOrderCompleteWasPressed() {
        ServiceLocator.analytics.track(.orderFulfillmentCompleteButtonTapped)
        let reviewOrderViewModel = ReviewOrderViewModel(order: viewModel.order, products: viewModel.products, showAddOns: viewModel.dataSource.showAddOns)
        let controller = ReviewOrderViewController(viewModel: reviewOrderViewModel) { [weak self] in
            guard let self = self else { return }
            let fulfillmentProcess = self.viewModel.markCompleted()
            let presenter = OrderFulfillmentNoticePresenter()
            presenter.present(process: fulfillmentProcess)
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    func markOrderCompleteFromShippingLabels() {
        let fulfillmentProcess = self.viewModel.markCompleted()

        var cancellables = Set<AnyCancellable>()
        var cancellable: AnyCancellable = AnyCancellable { }
        cancellable = fulfillmentProcess.result.sink { completion in
            if case .failure(_) = completion {
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
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
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

        actionSheet.addDefaultActionWithTitle(Localization.ShippingLabelTrackingMoreMenu.copyTrackingNumberAction) { [weak self] _ in
            ServiceLocator.analytics.track(event: .shipmentTrackingMenu(action: .copy))
            self?.viewModel.dataSource.sendToPasteboard(shippingLabel.trackingNumber, includeTrailingNewline: false)
        }

        // Only shows the tracking action when there is a tracking URL.
        if let url = ShippingLabelTrackingURLGenerator.url(for: shippingLabel) {
            actionSheet.addDefaultActionWithTitle(Localization.ShippingLabelTrackingMoreMenu.trackShipmentAction) { [weak self] _ in
                guard let self = self else { return }
                ServiceLocator.analytics.track(event: .shipmentTrackingMenu(action: .track))
                let safariViewController = SFSafariViewController(url: url)
                safariViewController.modalPresentationStyle = .pageSheet
                self.present(safariViewController, animated: true, completion: nil)
            }
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = sourceView

        present(actionSheet, animated: true)
    }

    func editCustomerNoteTapped() {
        let viewModel = EditCustomerNoteViewModel(order: viewModel.order)
        let editNoteViewController = EditCustomerNoteHostingController(viewModel: viewModel)
        present(editNoteViewController, animated: true, completion: nil)

        ServiceLocator.analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowStarted(subject: .customerNote))
    }

    func editShippingAddressTapped() {
        let viewModel = EditOrderAddressFormViewModel(order: viewModel.order, type: .shipping)
        let editAddressViewController = EditOrderAddressHostingController(viewModel: viewModel)
        let navigationController = WooNavigationController(rootViewController: editAddressViewController)
        present(navigationController, animated: true, completion: nil)
    }

    @objc private func collectPayment(at: IndexPath) {
        viewModel.collectPayment(rootViewController: self, backButtonTitle: Localization.Payments.backToOrder) { [weak self] result in
            guard let self = self else { return }
            // Refresh date & view once payment has been collected.
            if result.isSuccess {
                self.syncOrderAfterPaymentCollection {
                    self.refreshCardPresentPaymentEligibility()
                }
            }
        }
        return

        cardReaderAvailableSubscription = viewModel.cardReaderAvailable()
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.dismiss(animated: false, completion: {
                        self?.collectPaymentForCurrentOrder()
                    })
                    self?.cardReaderAvailableSubscription = nil
                },
                receiveValue: { [weak self] _ in
                    self?.connectToCardReader()
                })
    }

    private func collectPaymentForCurrentOrder() {
        let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
        let currencyCode = ServiceLocator.currencySettings.currencyCode
        let unit = ServiceLocator.currencySettings.symbol(from: currencyCode)
        let value = currencyFormatter.formatAmount(viewModel.order.total, with: unit) ?? ""

        paymentAlerts.readerIsReady(title: viewModel.collectPaymentFrom,
                                    amount: value)

        ServiceLocator.analytics.track(.collectPaymentTapped)
        viewModel.collectPayment(
            onWaitingForInput: { [weak self] in
                self?.paymentAlerts.tapOrInsertCard(onCancel: {
                	self?.viewModel.cancelPayment(onCompletion: { _ in
                	    ServiceLocator.analytics.track(.collectPaymentCanceled)
                	})
		})
            },
            onProcessingMessage: { [weak self] in
                self?.paymentAlerts.processingPayment()
            },
            onDisplayMessage: { [weak self] message in // display a message from the reader, e.g. "Remove Card"
                self?.paymentAlerts.displayReaderMessage(message: message)
            },
            onCompletion: { [weak self] result in
                guard let self = self else {
                    return
                }

                switch result {
                case .failure(let error):
                    ServiceLocator.analytics.track(.collectPaymentFailed, withError: error)
                    DDLogError("Failed to collect payment: \(error.localizedDescription)")
                    self.paymentAlerts.error(error: error, tryAgain: {
                        self.retryCollectPayment()
                    })
                case .success(let receiptParameters):
                    ServiceLocator.analytics.track(.collectPaymentSuccess)
                    self.syncOrderAfterPaymentCollection {
                        self.refreshCardPresentPaymentEligibility()
                    }

                    self.paymentAlerts.success(printReceipt: {
                        self.viewModel.printReceipt(params: receiptParameters)
                    }, emailReceipt: {
                        self.viewModel.emailReceipt(params: receiptParameters, onContent: { emailContent in
                            self.emailReceipt(emailContent)
                        })
                    }, noReceiptTitle: Localization.Payments.backToOrder,
                       noReceiptAction: {})
                }
            }
        )
    }

    private func retryCollectPayment() {
        viewModel.cancelPayment { [weak self] result in
            switch result {
            case .failure(let error):
                self?.paymentAlerts.nonRetryableError(from: self, error: error)
            case .success:
                self?.collectPaymentForCurrentOrder()
            }
        }
    }

    private func connectToCardReader() {
        connectionController?.searchAndConnect(from: self) { _ in
            /// No need for logic here. Once connected, the connected reader will publish
            /// through the `cardReaderAvailableSubscription`
        }
    }

    private func cancelObservingCardReader() {
        cardReaderAvailableSubscription?.cancel()
        cardReaderAvailableSubscription = nil
    }

    private func itemAddOnsButtonTapped(addOns: [OrderItemAttribute]) {
        let addOnsViewModel = OrderAddOnListI1ViewModel(attributes: addOns)
        let addOnsController = OrderAddOnsListViewController(viewModel: addOnsViewModel)
        let navigationController = WooNavigationController(rootViewController: addOnsController)
        present(navigationController, animated: true, completion: nil)
    }

    private func emailReceipt(_ content: String) {
        guard MFMailComposeViewController.canSendMail() else {
            DDLogError("⛔️ Failed to submit email receipt for order: \(viewModel.order.orderID). Email is not configured")
            return
        }

        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self

        mail.setSubject(viewModel.paymentReceiptEmailSubject)
        mail.setMessageBody(content, isHTML: true)

        if let customerEmail = viewModel.order.billingAddress?.email {
            mail.setToRecipients([customerEmail])
        }

        present(mail, animated: true)
    }
}

extension OrderDetailsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            ServiceLocator.analytics.track(.receiptEmailCanceled)
        case .sent, .saved:
            ServiceLocator.analytics.track(.receiptEmailSuccess)
        case .failed:
            ServiceLocator.analytics.track(.receiptEmailFailed, withError: error ?? UnknownEmailError())
        @unknown default:
            assertionFailure("MFMailComposeViewController finished with an unknown result type")
        }
        controller.dismiss(animated: true)
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

extension OrderDetailsViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        cancelObservingCardReader()
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

        let statusList = OrderStatusListViewController(siteID: viewModel.order.siteID,
                                                       status: viewModel.order.status)

        statusList.didSelectCancel = { [weak statusList] in
            statusList?.dismiss(animated: true, completion: nil)
        }

        statusList.didSelectApply = { [weak statusList] (selectedStatus) in
            statusList?.dismiss(animated: true) {
                self.setOrderStatus(to: selectedStatus)
            }
        }

        let navigationController = WooNavigationController(rootViewController: statusList)

        present(navigationController, animated: true)
    }

    func setOrderStatus(to newStatus: OrderStatusEnum) {
        let orderID = viewModel.order.orderID
        let undoStatus = viewModel.order.status
        let done = updateOrderStatusAction(siteID: viewModel.order.siteID, orderID: viewModel.order.orderID, status: newStatus)
        let undo = updateOrderStatusAction(siteID: viewModel.order.siteID, orderID: viewModel.order.orderID, status: undoStatus)

        ServiceLocator.stores.dispatch(done)

        ServiceLocator.analytics.track(.orderStatusChange,
                                       withProperties: ["id": orderID,
                                                        "from": undoStatus.rawValue,
                                                        "to": newStatus.rawValue])

        displayOrderStatusUpdatedNotice {
            ServiceLocator.stores.dispatch(undo)
            ServiceLocator.analytics.track(.orderStatusChange,
                                           withProperties: ["id": orderID,
                                                            "from": newStatus.rawValue,
                                                            "to": undoStatus.rawValue])
        }
    }

    /// Returns an Order Update Action that will result in the specified Order Status updated accordingly.
    ///
    private func updateOrderStatusAction(siteID: Int64, orderID: Int64, status: OrderStatusEnum) -> Action {
        return OrderAction.updateOrderStatus(siteID: siteID, orderID: orderID, status: status, onCompletion: { [weak self] error in
            guard let error = error else {
                NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)
                self?.syncNotes()
                ServiceLocator.analytics.track(.orderStatusChangeSuccess)
                return
            }

            ServiceLocator.analytics.track(.orderStatusChangeFailed, withError: error)
            DDLogError("⛔️ Order Update Failure: [\(orderID).status = \(status)]. Error: \(error)")

            self?.displayOrderStatusErrorNotice(orderID: orderID, status: status)
        })
    }

    /// Enqueues the `Order Updated` Notice. Whenever the `Undo` button gets pressed, we'll execute the `onUndoAction` closure.
    ///
    private func displayOrderStatusUpdatedNotice(onUndoAction: @escaping () -> Void) {
        let message = NSLocalizedString("Order status updated", comment: "Order status update success notice")
        let actionTitle = NSLocalizedString("Undo", comment: "Undo Action")
        let notice = Notice(title: message, feedbackType: .success, actionTitle: actionTitle, actionHandler: onUndoAction)

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Enqueues the `Unable to Change Status of Order` Notice.
    ///
    private func displayOrderStatusErrorNotice(orderID: Int64, status: OrderStatusEnum) {
        let titleFormat = NSLocalizedString(
            "Unable to change status of order #%1$d",
            comment: "Content of error presented when updating the status of an Order fails. "
            + "It reads: Unable to change status of order #{order number}. "
            + "Parameters: %1$d - order number"
        )
        let title = String.localizedStringWithFormat(titleFormat, orderID)
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: title, message: nil, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.setOrderStatus(to: status)
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

        enum Payments {
            static let backToOrder = NSLocalizedString("Back to Order",
                                                       comment: "Button to dismiss modal overlay and go back to the order after a sucessful payment")
        }
    }

    enum Constants {
        static let headerDefaultHeight = CGFloat(130)
        static let headerContainerInsets = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
    }

    /// Mailing a receipt failed but the SDK didn't return a more specific error
    ///
    struct UnknownEmailError: Error {}
}
