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
