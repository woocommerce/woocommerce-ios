import Foundation
import Yosemite
import protocol WooFoundation.Analytics
import enum Networking.DotcomError
import enum Networking.NetworkError

/// View model for `ProductStockDashboardCard`
///
@MainActor
final class ProductStockDashboardCardViewModel: ObservableObject {
    // Set externally to trigger callback upon hiding the Inbox card.
    var onDismiss: (() -> Void)?

    @Published private(set) var reports: [ProductReport] = []
    @Published private(set) var syncingData = false
    @Published private(set) var syncingError: Error?
    @Published private(set) var selectedStockType: StockType = .lowStock
    @Published private(set) var analyticsEnabled = true

    let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics

    /// In-memory list of loaded reports by product IDs.
    private var savedReports: [Int64: ProductReport] = [:]

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.analytics = analytics
        self.stores = stores

        Task { @MainActor in
            selectedStockType = await loadLastSelectedStockType()
        }
    }

    @MainActor
    func reloadData() async {
        analytics.track(event: .DynamicDashboard.cardLoadingStarted(type: .stock))
        syncingData = true
        syncingError = nil
        do {
            let stock = try await fetchStock(type: selectedStockType)
            try await fetchAndSaveReportsToMemory(for: stock)
            reports = stock.compactMap { item in
                savedReports[item.productID]
            }
            .sorted { ($0.stockQuantity ?? 0) < ($1.stockQuantity ?? 0) }

            analyticsEnabled = true
            analytics.track(event: .DynamicDashboard.cardLoadingCompleted(type: .stock))
        } catch {
            switch error {
            case DotcomError.noRestRoute, NetworkError.notFound:
                analyticsEnabled = false
            default:
                analyticsEnabled = true
            }
            syncingError = error
            analytics.track(event: .DynamicDashboard.cardLoadingFailed(type: .stock, error: error))
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
                                                           order: .ascending) { result in
                continuation.resume(with: result)
            })
        }
    }

    @MainActor
    func fetchProductReports(productIDs: [Int64]) async throws -> [ProductReport] {
        let timeZone = TimeZone.siteTimezone
        let currentDate = Date().endOfDay(timezone: timeZone)
        let last30Days = Date(timeInterval: -Constants.dayInSeconds*30, since: currentDate).startOfDay(timezone: timeZone)
        return try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.fetchProductReports(siteID: siteID,
                                                              productIDs: productIDs,
                                                              timeZone: timeZone,
                                                              earliestDateToInclude: last30Days,
                                                              latestDateToInclude: currentDate,
                                                              pageSize: Constants.maxItemCount,
                                                              pageNumber: Constants.pageNumber,
                                                              orderBy: .itemsSold,
                                                              order: .descending) { result in
                continuation.resume(with: result)
            })
        }
    }

    @MainActor
    func fetchVariationReports(productIDs: [Int64], variationIDs: [Int64]) async throws -> [ProductReport] {
        let timeZone = TimeZone.siteTimezone
        let currentDate = Date().endOfDay(timezone: timeZone)
        let last30Days = Date(timeInterval: -Constants.dayInSeconds*30, since: currentDate).startOfDay(timezone: timeZone)
        return try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.fetchVariationReports(siteID: siteID,
                                                                productIDs: productIDs,
                                                                variationIDs: variationIDs,
                                                                timeZone: timeZone,
                                                                earliestDateToInclude: last30Days,
                                                                latestDateToInclude: currentDate,
                                                                pageSize: Constants.maxItemCount,
                                                                pageNumber: Constants.pageNumber,
                                                                orderBy: .itemsSold,
                                                                order: .descending) { result in
                continuation.resume(with: result)
            })
        }
    }

    @MainActor
    func fetchAndSaveReportsToMemory(for stock: [ProductStock]) async throws {

        let groupedStockByVariations = Dictionary(grouping: stock, by: { $0.isProductVariation })
        let variationsToFetchReports = groupedStockByVariations[true] ?? []
        let productsToFetchReports = groupedStockByVariations[false] ?? []

        let reports = try await withThrowingTaskGroup(of: [ProductReport].self, returning: [ProductReport].self) { [weak self] group in
            guard let self else {
                return []
            }
            var allReports: [ProductReport] = []

            if variationsToFetchReports.isNotEmpty {
                group.addTask {
                    let reports = try await self.fetchVariationReports(
                        productIDs: Array(Set(variationsToFetchReports.map { $0.parentID })),
                        variationIDs: variationsToFetchReports.map { $0.productID }
                    )
                    return reports.map { report in
                        guard let variationID = report.variationID,
                              report.productID == 0,
                              let parentID = stock.first(where: { $0.productID == variationID })?.parentID else {
                            return report
                        }
                        /// For some stores, the product ID is not found for variations returned from variation reports.
                        /// We need to copy the parent ID from the stock report over to the variation reports
                        /// to be able to show the details for the variation upon selection.
                        return report.copy(productID: parentID)
                    }
                }
            }

            if productsToFetchReports.isNotEmpty {
                group.addTask {
                    try await self.fetchProductReports(productIDs: productsToFetchReports.map { $0.productID })
                }
            }

            // rethrow any failure.
            for try await items in group {
                // gather the results
                allReports.append(contentsOf: items)
            }

            return allReports
        }

        /// Saves loaded reports to memory
        for report in reports {
            let id = report.variationID ?? report.productID
            savedReports[id] = report
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

extension ProductReport: Identifiable {
    public var id: String { "\(productID)-\(variationID ?? 0)" }
}
