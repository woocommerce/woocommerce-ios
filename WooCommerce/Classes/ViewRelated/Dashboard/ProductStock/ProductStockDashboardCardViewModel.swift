import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// View model for `ProductStockDashboardCard`
///
final class ProductStockDashboardCardViewModel: ObservableObject {
    // Set externally to trigger callback upon hiding the Inbox card.
    var onDismiss: (() -> Void)?

    @Published private(set) var stock: [StockItem] = []
    @Published private(set) var syncingData = false
    @Published private(set) var syncingError: Error?
    @Published private(set) var selectedStockType: StockType = .lowStock

    let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics

    /// In-memory list of loaded items sold by product IDs.
    private var itemsSoldLast30Days: [Int64: Int] = [:]

    /// In-memory list of loaded product thumbnails by product IDs.
    private var productThumbnails: [Int64: URL?] = [:]

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
        do {
            let productStock = try await fetchStock(type: selectedStockType)
            let productIDs = productStock.map { $0.productID }
            try await saveStockDetailsToMemory(for: productIDs)
            stock = productStock.map { item in
                let quantity: Int = {
                    guard let stockQuantity = item.stockQuantity else {
                        return 0
                    }
                    return Int(truncating: stockQuantity as NSNumber)
                }()
                return StockItem(productID: item.productID,
                                 productName: item.name,
                                 stockQuantity: quantity,
                                 thumbnailURL: productThumbnails[item.productID] ?? nil,
                                 itemsSoldLast30Days: itemsSoldLast30Days[item.productID] ?? 0)
            }
        } catch {
            syncingError = error
        }
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

    @MainActor
    func saveStockDetailsToMemory(for productIDs: [Int64]) async throws {
        let idsToFetchItemsSold: [Int64] = productIDs.filter { !itemsSoldLast30Days.keys.contains($0) }
        let idsToFetchProductDetails: [Int64] = productIDs.filter { !productThumbnails.keys.contains($0) }

        try await withThrowingTaskGroup(of: Void.self) { [weak self] group in
            guard let self else { return }

            if idsToFetchItemsSold.isNotEmpty {
                group.addTask {
                    let segments = try await self.fetchProductReports(productIDs: idsToFetchItemsSold)
                    for segment in segments {
                        self.itemsSoldLast30Days[segment.productID] = segment.subtotals.itemsSold
                    }
                }
            }

            if idsToFetchProductDetails.isNotEmpty {
                group.addTask {
                    let products = try await self.fetchProductDetails(productIDs: idsToFetchProductDetails)
                    for product in products {
                        self.productThumbnails[product.productID] = product.imageURL
                    }
                }
            }

            while !group.isEmpty {
                // rethrow any failure.
                try await group.next()
            }
        }
    }
}

extension ProductStockDashboardCardViewModel {
    struct StockItem: Identifiable, Hashable {
        let productID: Int64
        let productName: String
        let stockQuantity: Int
        let thumbnailURL: URL?
        let itemsSoldLast30Days: Int

        var id: Int64 { productID }
    }

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
