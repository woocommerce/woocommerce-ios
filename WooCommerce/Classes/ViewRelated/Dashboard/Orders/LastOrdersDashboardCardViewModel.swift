import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// View model for `LastOrdersDashboardCard`
///
final class LastOrdersDashboardCardViewModel: ObservableObject {
    enum OrderStatusRow: Identifiable {
        case any
        case pending
        case processing
        case onHold
        case completed
        case cancelled
        case refunded
        case failed
        case custom(OrderStatus)

        var status: OrderStatusEnum? {
            switch self {
            case .any:
                return nil
            case .pending:
                return .pending
            case .processing:
                return .processing
            case .onHold:
                return .onHold
            case .failed:
                return .failed
            case .cancelled:
                return .cancelled
            case .completed:
                return .completed
            case .refunded:
                return .refunded
            case .custom(let value):
                return value.status
            }
        }

        var id: String {
            status?.rawValue ?? "any"
        }

        var description: String {
            status?.description ?? Localization.anyStatusCase
        }
    }
    // Set externally to trigger callback upon hiding the Inbox card.
    var onDismiss: (() -> Void)?

    @Published private(set) var syncingData = false
    @Published private(set) var syncingError: Error?
    @Published private(set) var selectedOrderStatus: OrderStatusEnum?
    @Published private(set) var rows: [LastOrderDashboardRowViewModel] = []

    var allStatuses: [OrderStatusRow] {
        [.any,
         .pending,
         .processing,
         .onHold,
         .completed,
         .cancelled,
         .refunded,
         .failed,
         // TODO: 12792 Load custom statuses from storage
         .custom(.init(name: "free-gift", siteID: siteID, slug: "Free gift", total: 1))]
    }

    var status: String {
        selectedOrderStatus?.description ?? Localization.anyStatusCase
    }

    private let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics
    private var resultsController: ResultsController<StorageOrder>?

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.analytics = analytics
        self.stores = stores
        self.storageManager = storageManager
    }

    @MainActor
    func reloadData() async {
        syncingData = true
        syncingError = nil
        rows = []
        configureResultsController()

        do {
            // Send network request -> listen to storage -> load UI
            try await loadLast3Orders(for: selectedOrderStatus)
        } catch {
            syncingError = error
            DDLogError("⛔️ Dashboard (Last orders) — Error loading orders: \(error)")
        }
        syncingData = false
    }

    func dismiss() {
        analytics.track(event: .DynamicDashboard.hideCardTapped(type: .lastOrders))
        onDismiss?()
    }

    func updateOrderStatus(_ status: OrderStatusRow) {
        selectedOrderStatus = status.status

        Task {
            await reloadData()
        }
    }
}

private extension LastOrdersDashboardCardViewModel {
    func ordersPredicate() -> NSPredicate {
        let sitePredicate = NSPredicate(format: "siteID == %lld", siteID)

        guard let slug = selectedOrderStatus?.rawValue else {
            return sitePredicate
        }

        let statusPredicate = NSPredicate(format: "statusKey == [c] %@", slug)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [statusPredicate, sitePredicate])
    }

    @MainActor
    func loadLast3Orders(for status: OrderStatusEnum?) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(OrderAction.synchronizeOrders(
                siteID: siteID,
                statuses: [status?.rawValue].compactMap { $0 },
                pageNumber: Constants.pageNumber,
                pageSize: Constants.numberOfOrdersToShow,
                onCompletion: { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }))
        }
    }

    func configureResultsController() {
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageOrder.dateCreated, ascending: false)
        let resultsController = ResultsController<StorageOrder>(storageManager: storageManager,
                                                                matching: ordersPredicate(),
                                                                fetchLimit: Constants.numberOfOrdersToShow,
                                                                sortedBy: [sortDescriptorByID])
        self.resultsController = resultsController
        resultsController.onDidChangeContent = { [weak self] in
            self?.updateResults()
        }
        resultsController.onDidResetContent = { [weak self] in
            self?.updateResults()
        }

        do {
            try resultsController.performFetch()
            updateResults()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    /// Updates row view models.
    func updateResults() {
        if let orders = resultsController?.fetchedObjects {
            rows = orders
                .prefix(Constants.numberOfOrdersToShow)
                .map { LastOrderDashboardRowViewModel(order: $0) }
        }
    }
}

// MARK: Constants
//
private extension LastOrdersDashboardCardViewModel {
    enum Constants {
        static let pageNumber = 1
        static let numberOfOrdersToShow = 3
    }

    enum Localization {
        static let anyStatusCase = NSLocalizedString(
            "lastOrdersDashboardCardViewModel.anyStatusCase",
            value: "Any",
            comment: "Case Any in Order Filters for Order Statuses"
        )
    }
}
