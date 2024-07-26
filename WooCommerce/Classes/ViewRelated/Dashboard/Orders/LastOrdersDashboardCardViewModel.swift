import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// View model for `LastOrdersDashboardCard`
///
@MainActor
final class LastOrdersDashboardCardViewModel: ObservableObject {
    enum OrderStatusRow: Identifiable {
        case any
        case autoDraft
        case pending
        case processing
        case onHold
        case completed
        case cancelled
        case refunded
        case failed
        case custom(String)

        init(_ status: OrderStatusEnum?) {
            guard let status else {
                self = .any
                return
            }

            switch status {
            case .autoDraft:
                self = .autoDraft
            case .pending:
                self = .pending
            case .processing:
                self = .processing
            case .onHold:
                self = .onHold
            case .failed:
                self = .failed
            case .cancelled:
                self = .cancelled
            case .completed:
                self = .completed
            case .refunded:
                self = .refunded
            case .custom(let value):
                self = .custom(value)
            }
        }

        var status: OrderStatusEnum? {
            switch self {
            case .autoDraft:
                return .autoDraft
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
                return .custom(value)
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
    @Published private(set) var allStatuses: [OrderStatusRow] = []

    var status: String {
        selectedOrderStatus?.description ?? Localization.anyStatusCase
    }

    private let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics

    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)

        return ResultsController<StorageOrderStatus>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.analytics = analytics
        self.stores = stores
        self.storageManager = storageManager

        Task { @MainActor in
            selectedOrderStatus = await loadLastSelectedOrderStatus()
        }

        configureStatusResultsController()
    }

    @MainActor
    func reloadData() async {
        analytics.track(event: .DynamicDashboard.cardLoadingStarted(type: .lastOrders))
        syncingData = true
        syncingError = nil
        rows = []

        do {
            async let orders = loadLast3Orders(for: selectedOrderStatus)
            try? await loadOrderStatuses()
            rows = try await orders
                .map { LastOrderDashboardRowViewModel(order: $0) }
            analytics.track(event: .DynamicDashboard.cardLoadingCompleted(type: .lastOrders))
        } catch {
            syncingError = error
            DDLogError("⛔️ Dashboard (Last orders) — Error loading orders: \(error)")
            analytics.track(event: .DynamicDashboard.cardLoadingFailed(type: .lastOrders, error: error))
        }
        syncingData = false
    }

    func dismiss() {
        analytics.track(event: .DynamicDashboard.hideCardTapped(type: .lastOrders))
        onDismiss?()
    }

    @MainActor
    func updateOrderStatus(_ status: OrderStatusRow) async {
        guard selectedOrderStatus != status.status else {
            /// Do nothing if the same status is selected.
            return
        }
        selectedOrderStatus = status.status
        stores.dispatch(AppSettingsAction.setLastSelectedOrderStatus(siteID: siteID, status: selectedOrderStatus?.rawValue))

        await reloadData()
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
    func loadLast3Orders(for status: OrderStatusEnum?) async throws -> [Order] {
        return try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(OrderAction.fetchFilteredOrders(
                siteID: siteID,
                statuses: [status?.rawValue].compactMap { $0 },
                writeStrategy: .doNotSave,
                pageSize: Constants.numberOfOrdersToShow,
                onCompletion: { _, result in
                    switch result {
                    case .success(let orders):
                        continuation.resume(returning: orders)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }))
        }
    }

    @MainActor
    func loadOrderStatuses() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(OrderStatusAction.retrieveOrderStatuses(siteID: siteID) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }

    func configureStatusResultsController() {
        statusResultsController.onDidChangeContent = { [weak self] in
            self?.updateStatuses()
        }
        statusResultsController.onDidResetContent = { [weak self] in
            self?.updateStatuses()
        }

        do {
            try statusResultsController.performFetch()
            updateStatuses()
        } catch {
            DDLogError("⛔️ Dashboard (Last orders) — Unable to fetch Order Statuses: \(error)")
        }
    }

    func updateStatuses() {
        let remoteStatuses = statusResultsController.fetchedObjects
            .map { OrderStatusEnum(rawValue: $0.slug) }
            .map { OrderStatusRow($0) }
        allStatuses = [.any] + remoteStatuses
    }

    @MainActor
    func loadLastSelectedOrderStatus() async -> OrderStatusEnum? {
        return await withCheckedContinuation { continuation in
            stores.dispatch(AppSettingsAction.loadLastSelectedOrderStatus(siteID: siteID, onCompletion: { rawStatus in
                guard let rawStatus else {
                    return continuation.resume(returning: nil)
                }
                continuation.resume(returning: OrderStatusEnum(rawValue: rawStatus))
            }))
        }
    }
}

// MARK: Constants
//
private extension LastOrdersDashboardCardViewModel {
    enum Constants {
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
