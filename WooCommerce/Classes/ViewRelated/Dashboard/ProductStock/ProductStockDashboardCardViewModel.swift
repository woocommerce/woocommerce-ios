import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// View model for `ProductStockDashboardCard`
///
final class ProductStockDashboardCardViewModel: ObservableObject {
    // Set externally to trigger callback upon hiding the Inbox card.
    var onDismiss: (() -> Void)?

    @Published private(set) var syncingData = false
    @Published private(set) var syncingError: Error?
    @Published private(set) var selectedStockType: StockType = .lowStock

    let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.analytics = analytics
        self.stores = stores
        self.storageManager = storageManager

        Task { @MainActor in
            selectedStockType = await loadLastSelectedStockType()
        }
    }

    @MainActor
    func reloadData() async {
        syncingData = true
        syncingError = nil
        // TODO: replace this with actual remote requests
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        syncingData = false
    }

    func dismissStock() {
        analytics.track(event: .DynamicDashboard.hideCardTapped(type: .stock))
        onDismiss?()
    }

    func updateStockType(_ type: StockType) {
        selectedStockType = type
        stores.dispatch(AppSettingsAction.setLastSelectedStockType(siteID: siteID, type: type.rawValue))
        Task {
            await reloadData()
        }
    }
}

private extension ProductStockDashboardCardViewModel {
    @MainActor
    func loadLastSelectedStockType() async -> StockType {
        await withCheckedContinuation { continuation in
            stores.dispatch(AppSettingsAction.loadLastSelectedStockType(siteID: siteID, onCompletion: { type in
                guard let type,
                      let stockType = StockType(rawValue: type) else {
                    continuation.resume(returning: .lowStock)
                    return
                }
                continuation.resume(returning: stockType)
            }))
        }
    }

    @MainActor
    func fetchStock(type: StockType) async throws -> [ProductStock] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.fetchStockReport(siteID: siteID,
                                                           stockType: type.rawValue,
                                                           pageNumber: Constants.pageNumber,
                                                           pageSize: Constants.maxItemCount,
                                                           orderBy: .date,
                                                           order: .descending) { result in
                continuation.resume(with: result)
            })
        }
    }

    @MainActor
    func fetchProductReports(productIDs: [Int64]) async throws -> [ProductReportSegment] {
        let timeZone = TimeZone.siteTimezone
        let currentDate = Date().endOfDay(timezone: timeZone)
        let last30Days = Date(timeInterval: -Constants.dayInSeconds*30, since: currentDate).startOfDay(timezone: timeZone)
        return try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.fetchProductReports(siteID: siteID,
                                                              productIDs: productIDs,
                                                              timeZone: timeZone,
                                                              earliestDateToInclude: currentDate,
                                                              latestDateToInclude: last30Days,
                                                              pageSize: Constants.maxItemCount,
                                                              pageNumber: Constants.pageNumber,
                                                              orderBy: .itemsSold,
                                                              order: .descending) { result in
                continuation.resume(with: result)
            })
        }
    }

    @MainActor
    func fetchProductDetails(productIDs: [Int64]) async throws -> [Product] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.retrieveProducts(siteID: siteID,
                                                           productIDs: productIDs,
                                                           pageNumber: Constants.pageNumber,
                                                           pageSize: Constants.maxItemCount) { result in
                switch result {
                case let .success((products, _)):
                    continuation.resume(returning: products)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }
}

extension ProductStockDashboardCardViewModel {
    enum StockType: String, CaseIterable, Identifiable {
        case lowStock = "lowstock"
        case outOfStock = "outofstock"
        case onBackOrder = "onbackorder"

        /// Identifiable conformance
        var id: String { rawValue }

        var displayedName: String {
            switch self {
            case .lowStock:
                Localization.lowStock
            case .outOfStock:
                Localization.outOfStock
            case .onBackOrder:
                Localization.onBackOrder
            }
        }

        private enum Localization {
            static let lowStock = NSLocalizedString(
                "productStockDashboardCardViewModel.stockType.lowStock",
                value: "Low stock",
                comment: "Title of a stock type displayed on the Stock section on My Store screen"
            )
            static let outOfStock = NSLocalizedString(
                "productStockDashboardCardViewModel.stockType.outOfStock",
                value: "Out of stock",
                comment: "Title of a stock type displayed on the Stock section on My Store screen"
            )
            static let onBackOrder = NSLocalizedString(
                "productStockDashboardCardViewModel.stockType.onBackOrder",
                value: "On back order",
                comment: "Title of a stock type displayed on the Stock section on My Store screen"
            )
        }
    }
}

private extension ProductStockDashboardCardViewModel {
    enum Constants {
        static let pageNumber = 1
        static let maxItemCount = 3
        static let dayInSeconds: TimeInterval = 86400
    }
}
