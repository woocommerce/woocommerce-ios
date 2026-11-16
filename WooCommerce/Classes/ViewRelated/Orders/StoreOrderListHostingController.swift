import SafariServices
import StoreDesignSystem
import SwiftUI
import UIKit
import WooFoundation
import Yosemite

private typealias SyncReason = OrderListSyncActionUseCase.SyncReason

@MainActor
final class StoreOrderListHostingController: UIHostingController<StoreOrderListScreen>, OrderListPresenting {
    weak var delegate: OrderListViewControllerDelegate?
    var onFilterTapped: (() -> Void)? {
        didSet { adapter.onFilterTapped = onFilterTapped }
    }

    var viewController: UIViewController { self }
    private(set) weak var contentScrollView: UIScrollView?

    private let siteID: Int64
    private let viewModel: OrderListViewModel
    private let stores: StoresManager
    private let switchDetailsHandler: OrderListViewController.SelectOrderDetails
    private let adapter: StoreOrderListAdapter
    private let syncingCoordinator = SyncingCoordinator()
    private var contentScrollViewObservers: [(UIScrollView) -> Void] = []
    private var noticePresenter: NoticePresenter = DefaultNoticePresenter()

    private(set) var lastFullSyncTimestamp: Date {
        get { OrderListSyncBackgroundTask.latestSyncDate }
        set {
            OrderListSyncBackgroundTask.latestSyncDate = newValue
            delegate?.orderListViewControllerSyncTimestampChanged(newValue)
        }
    }

    private let minimalIntervalBetweenSync = TimeInterval(30 * 60)

    init(siteID: Int64,
         viewModel: OrderListViewModel,
         stores: StoresManager = ServiceLocator.stores,
         switchDetailsHandler: @escaping OrderListViewController.SelectOrderDetails) {
        self.siteID = siteID
        self.viewModel = viewModel
        self.stores = stores
        self.switchDetailsHandler = switchDetailsHandler
        self.adapter = StoreOrderListAdapter(viewModel: viewModel)
        super.init(rootView: StoreOrderListScreen(adapter: adapter))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(Color.storeSectionBackground)
        registerUserActivity()
        configureAdapter()
        configureViewModel()
        syncingCoordinator.delegate = self
        adapter.activate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncingCoordinator.resynchronize(reason: SyncReason.viewWillAppear.rawValue)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard splitViewController?.isCollapsed == false else { return }
        checkSelectedItem()
    }

    func observeContentScrollView(_ observer: @escaping (UIScrollView) -> Void) {
        contentScrollViewObservers.append(observer)
        if let contentScrollView {
            observer(contentScrollView)
        }
    }

    func updateFilters(count: Int, readableDescription: String?) {
        adapter.updateFilters(count: count, readableDescription: readableDescription)
    }

    func updateLastSyncTime(_ time: String) {
        adapter.updateLastSyncTime(time)
    }

    func onOrderSelected(id orderID: Int64, shouldScrollIfNeeded: Bool = false) {
        adapter.selectedOrderID = orderID
        if shouldScrollIfNeeded {
            adapter.scrollTargetOrderID = orderID
        }
    }

    @discardableResult
    func selectOrderFromListIfPossible(for orderID: Int64,
                                       isTriggeredByUserAction: Bool = false,
                                       shouldScrollIfNeeded: Bool = false) -> Bool {
        guard let row = adapter.row(withID: orderID) else { return false }
        let shouldSwitchDetails = adapter.selectedOrderID != orderID || isTriggeredByUserAction
        if shouldSwitchDetails {
            showOrderDetails(row.detailsViewModel.order, shouldScrollIfNeeded: shouldScrollIfNeeded)
        } else {
            onOrderSelected(id: orderID, shouldScrollIfNeeded: shouldScrollIfNeeded)
        }
        return true
    }

    func selectShownOrderIfListed(id orderID: Int64) {
        guard adapter.row(withID: orderID) != nil else { return }
        onOrderSelected(id: orderID, shouldScrollIfNeeded: true)
    }

    func restoreSelectedOrderDetails() {
        checkSelectedItem(forceShowingDetails: true)
    }

    func showOrderDetails(_ order: Order,
                          shouldScrollIfNeeded: Bool = false,
                          onCompletion: ((Bool) -> Void)? = nil) {
        let detailsViewModel = OrderDetailsViewModel(order: order)
        switchDetailsHandler([detailsViewModel], 0, true) { [weak self] hasBeenSelected in
            guard let self else { return }
            if hasBeenSelected {
                self.onOrderSelected(id: order.orderID, shouldScrollIfNeeded: shouldScrollIfNeeded)
            }
            onCompletion?(hasBeenSelected)
        }
    }

    func showErrorNotice(_ notice: Notice, in viewController: UIViewController) {
        noticePresenter.presentingViewController = viewController
        noticePresenter.enqueue(notice: notice)
    }
}

private extension StoreOrderListHostingController {
    func configureAdapter() {
        adapter.onContentScrollViewResolved = { [weak self] scrollView in
            guard let self, scrollView !== self.contentScrollView else { return }
            self.contentScrollView = scrollView
            self.contentScrollViewObservers.forEach { $0(scrollView) }
        }
        adapter.onScroll = { [weak self] in
            guard let self, let contentScrollView = self.contentScrollView else { return }
            self.delegate?.orderListScrollViewDidScroll(contentScrollView)
        }
        adapter.onRefresh = { [weak self] in
            guard let self else { return }
            await withCheckedContinuation { continuation in
                ServiceLocator.analytics.track(.ordersListPulledToRefresh)
                self.delegate?.orderListViewControllerWillSynchronizeOrders(self)
                NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)
                self.syncingCoordinator.resynchronize(reason: SyncReason.pullToRefresh.rawValue) {
                    continuation.resume()
                }
            }
        }
        adapter.onOrderSelected = { [weak self] orderID in
            self?.selectOrderFromUserAction(orderID)
        }
        adapter.onOrderAppeared = { [weak self] itemIndex in
            self?.syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: itemIndex)
        }
        adapter.onMarkCompleted = { [weak self] objectID in
            self?.markOrderAsCompleted(resultID: objectID)
        }
        adapter.onLearnMoreTapped = {
            WebviewHelper.launch(WooConstants.URLs.blog.asURL(), with: self)
        }
        adapter.onClearFiltersTapped = { [weak self] in
            self?.delegate?.clearFilters()
        }
        adapter.onRetryCurrencyTapped = { [weak self] in
            self?.viewModel.retryStoreCurrencySync()
        }
        adapter.onTroubleshootTapped = { [weak self] error in
            self?.showTroubleshooting(for: error)
        }
        adapter.onContactSupportTapped = { [weak self] in
            self?.showContactSupport()
        }
        adapter.onSnapshotChanged = { [weak self] in
            guard let self, self.viewIfLoaded?.window != nil,
                  self.splitViewController?.isCollapsed == false else { return }
            self.checkSelectedItem()
        }
    }

    func configureViewModel() {
        viewModel.onShouldResynchronize = { [weak self] reason in
            guard let self else { return }
            guard reason == .pushNotification || self.viewIfLoaded?.window != nil else { return }
            self.delegate?.orderListViewControllerSyncTimestampChanged(self.lastFullSyncTimestamp)
            self.syncingCoordinator.resynchronize(reason: reason.rawValue)
        }
        viewModel.onShouldResynchronizeIfNewFiltersAreApplied = { [weak self] in
            self?.syncingCoordinator.resynchronize(reason: SyncReason.newFiltersApplied.rawValue)
        }
    }

    func selectOrderFromUserAction(_ orderID: Int64) {
        guard let row = adapter.row(withID: orderID) else { return }
        let order = row.detailsViewModel.order
        ServiceLocator.analytics.track(event: WooAnalyticsEvent.Orders.orderOpen(order: order))
        adapter.selectedOrderID = orderID

        let allViewModels = adapter.allDetailsViewModels()
        guard let currentIndex = allViewModels.firstIndex(where: { $0.order.orderID == orderID }) else { return }
        let allowOrderNavigation = splitViewController?.isCollapsed ?? true
        allowOrderNavigation ? switchDetailsHandler(allViewModels, currentIndex, true, nil) :
            switchDetailsHandler([row.detailsViewModel], 0, true, nil)
    }

    func checkSelectedItem(forceShowingDetails: Bool = false) {
        if let selectedOrderID = adapter.selectedOrderID {
            if !selectOrderFromListIfPossible(for: selectedOrderID,
                                              isTriggeredByUserAction: forceShowingDetails,
                                              shouldScrollIfNeeded: false) {
                adapter.selectedOrderID = nil
                switchDetailsHandler([], 0, true, nil)
            }
            return
        }

        guard let first = adapter.allDetailsViewModels().first else {
            switchDetailsHandler([], 0, false, nil)
            return
        }
        switchDetailsHandler([first], 0, false) { [weak self] hasBeenSelected in
            if hasBeenSelected {
                self?.onOrderSelected(id: first.order.orderID)
            }
        }
    }

    func markOrderAsCompleted(resultID: FetchResultSnapshotObjectID) {
        guard let row = adapter.sections.lazy.flatMap(\.orders).first(where: { $0.objectID == resultID }) else {
            return DDLogError("⛔️ ViewModel for resultID: \(resultID) not found")
        }
        let orderDetailsViewModel = row.detailsViewModel
        let fulfillmentProcess = orderDetailsViewModel.markCompleted(flow: .list)
        let noticeConfiguration = OrderFulfillmentNoticePresenter.NoticeConfiguration(
            successTitle: OrderListLocalization.markCompletedNoticeTitle(orderID: orderDetailsViewModel.order.orderID),
            errorTitle: OrderListLocalization.markCompletedErrorNoticeTitle(orderID: orderDetailsViewModel.order.orderID)
        )
        OrderFulfillmentNoticePresenter(noticeConfiguration: noticeConfiguration).present(process: fulfillmentProcess)
    }

    func showTroubleshooting(for error: Error) {
        if adapter.sections.isEmpty {
            WebviewHelper.launch(ErrorTopBannerFactory.troubleshootUrl(for: error), with: self)
            return
        }
        ServiceLocator.analytics.track(event: .ConnectivityTool.topBannerTroubleshootTapped())
        show(ConnectivityToolViewController(), sender: self)
    }

    func showContactSupport() {
        let viewModel = SupportFormViewModel(mobileStatusReportProvider: MobileStatusReportProvider())
        SupportFormHostingController(viewModel: viewModel).show(from: self)
    }
}

extension StoreOrderListHostingController: SyncingCoordinatorDelegate {
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: ((Bool) -> Void)?) {
        sync(pageNumber: pageNumber,
             pageSize: pageSize,
             reason: reason,
             retryTimeout: true,
             onCompletion: onCompletion)
    }

    private func sync(pageNumber: Int,
                      pageSize: Int,
                      reason: String?,
                      retryTimeout: Bool,
                      onCompletion: ((Bool) -> Void)?) {
        if let syncReason = SyncReason(rawValue: reason ?? ""),
           pageNumber == syncingCoordinator.pageFirstIndex,
           syncReason == .viewWillAppear,
           Date.now.timeIntervalSince(lastFullSyncTimestamp) < minimalIntervalBetweenSync {
            onCompletion?(true)
            return
        }

        adapter.beginSync(isFirstPage: pageNumber == syncingCoordinator.pageFirstIndex)
        viewModel.dataLoadingError = nil
        let action = viewModel.synchronizationAction(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            reason: SyncReason(rawValue: reason ?? ""),
            lastFullSyncTimestamp: lastFullSyncTimestamp
        ) { [weak self] totalDuration, error in
            guard let self else { return }
            if let error {
                ServiceLocator.analytics.track(event: .ordersListLoadError(error))
                DDLogError("⛔️ Error synchronizing orders: \(error)")
                if error.isTimeoutError && retryTimeout {
                    self.sync(pageNumber: pageNumber,
                              pageSize: pageSize,
                              reason: reason,
                              retryTimeout: false,
                              onCompletion: onCompletion)
                    ServiceLocator.analytics.track(event: .ConnectivityTool.automaticTimeoutRetry())
                    return
                }
                self.viewModel.dataLoadingError = error
            } else {
                if pageNumber == self.syncingCoordinator.pageFirstIndex {
                    self.lastFullSyncTimestamp = .now
                }
                let totalCompletedOrderCount = self.viewModel.totalCompletedOrderCount(pageNumber: pageNumber)
                ServiceLocator.analytics.track(event: .ordersListLoaded(totalDuration: totalDuration,
                                                                        pageNumber: pageNumber,
                                                                        filters: self.viewModel.filters,
                                                                        totalCompletedOrders: totalCompletedOrderCount))
            }
            self.adapter.completeSync()
            onCompletion?(error == nil)
        }
        stores.dispatch(action)
    }
}
