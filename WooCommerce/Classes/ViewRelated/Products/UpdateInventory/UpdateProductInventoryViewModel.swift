import Combine
import Yosemite
import SwiftUI
import protocol WooFoundation.Analytics

enum UpdateInventoryError: Error {
    case nonSupportedQuantity
    case generic
}

/// An item whose inventory can be displayed and managed
///
protocol InventoryItem {
    var manageStock: Bool { get }
    var stockQuantity: Decimal? { get }
    var sku: String? { get }
    var imageURL: URL? { get }

    func retrieveName(with stores: StoresManager, siteID: Int64) async throws -> String

    /// Returns the updated inventory item
    ///
    func updateStockQuantity(with newQuantity: Decimal, stores: StoresManager) async throws -> InventoryItem
    func detailsView() -> ProductLoaderView

    /// Returns the updated inventory item
    ///
    func enableManageStock(stores: StoresManager) async throws -> InventoryItem
}

extension SKUSearchResult {
    var inventoryItem: InventoryItem {
        switch self {
        case .product(let product):
            return product
        case .variation(let variation):
            return variation
        }
    }
}

extension Product: InventoryItem {
    func retrieveName(with stores: StoresManager, siteID: Int64) async throws -> String {
        name
    }

    func updateStockQuantity(with newQuantity: Decimal, stores: StoresManager) async throws -> InventoryItem {
        try await updateProduct(product: copy(stockQuantity: newQuantity), stores: stores)
    }

    func detailsView() -> ProductLoaderView {
        ProductLoaderView(model: .product(productID: productID), siteID: siteID, forceReadOnly: true)
    }

    func enableManageStock(stores: StoresManager) async throws  -> InventoryItem {
        try await updateProduct(product: copy(manageStock: true), stores: stores)
    }

    private func updateProduct(product: Product, stores: StoresManager) async throws  -> InventoryItem {
        return try await withCheckedThrowingContinuation { continuation in
            let action = ProductAction.updateProduct(product: product) { result in
                switch result {
                case let .success(product):
                    continuation.resume(with: .success(product))
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }

            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }
}

extension ProductVariation: InventoryItem {
    func retrieveName(with stores: StoresManager, siteID: Int64) async throws -> String {
        // Let's retrieve the parent product's name
        return try await withCheckedThrowingContinuation { continuation in
            let action = ProductAction.retrieveProduct(siteID: siteID,
                                                       productID: productID) { result in
                switch result {
                case let .success(product):
                    continuation.resume(with: .success(product.name))
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }

            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    func updateStockQuantity(with newQuantity: Decimal, stores: StoresManager) async throws -> InventoryItem {
        try await updateProductVariation(productVariation: copy(stockQuantity: newQuantity), stores: stores)
    }

    func enableManageStock(stores: StoresManager) async throws  -> InventoryItem {
        try await updateProductVariation(productVariation: copy(manageStock: true), stores: stores)
    }

    func detailsView() -> ProductLoaderView {
        ProductLoaderView(model: .productVariation(productID: productID, variationID: productVariationID), siteID: siteID, forceReadOnly: true)
    }

    private func updateProductVariation(productVariation: ProductVariation, stores: StoresManager) async throws -> InventoryItem {
        return try await withCheckedThrowingContinuation { continuation in
            let action = ProductVariationAction.updateProductVariation(productVariation: productVariation) { result in
                switch result {
                case let .success(variation):
                    continuation.resume(with: .success(variation))
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }

            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }
}

@MainActor
final class UpdateProductInventoryViewModel: ObservableObject {
    enum UpdateQuantityButtonMode {
        case increaseOnce
        case customQuantity
    }

    enum ViewMode {
        case stockCanBeManaged
        case stockManagementNeedsToBeEnabled
    }

    private var inventoryItem: InventoryItem
    private let stores: StoresManager
    private let analytics: Analytics

    var onUpdatedInventory: ((String) -> ())

    init(inventoryItem: InventoryItem,
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onUpdatedInventory: @escaping ((String) -> ())) {
        self.inventoryItem = inventoryItem
        self.stores = stores
        self.analytics = analytics
        self.onUpdatedInventory = onUpdatedInventory

        refresh()

        Task { @MainActor in
            name = try await inventoryItem.retrieveName(with: stores, siteID: siteID)
            showLoadingName = false
        }
    }

    @Published var quantity: String = "" {
        didSet {
            guard quantity != oldValue else { return }

            guard let decimalValue = Decimal(string: quantity) else {
                enableQuantityButton = false
                return
            }

            enableQuantityButton = true
            guard let stockQuantity = inventoryItem.stockQuantity else {
                updateQuantityButtonMode = .increaseOnce
                return
            }
            updateQuantityButtonMode = decimalValue == stockQuantity ? .increaseOnce : .customQuantity
        }
    }

    @Published var isPrimaryButtonLoading: Bool = false
    @Published var isManageStockButtonLoading: Bool = false
    @Published var enableQuantityButton: Bool = true
    @Published var showLoadingName: Bool = true
    @Published var viewMode: ViewMode = .stockCanBeManaged
    @Published var name: String = ""
    @Published var updateQuantityButtonMode: UpdateQuantityButtonMode = .increaseOnce
    @Published var notice: Notice?

    var sku: String {
        inventoryItem.sku ?? ""
    }

    var imageURL: URL? {
        inventoryItem.imageURL
    }

    func onTapIncreaseStockQuantityOnce() async throws {
        analytics.track(.inventoryUpdateIncrementQuantityTapped)
        guard let quantityDecimal = Decimal(string: quantity) else {
            return
        }
        let newQuantity = quantityDecimal + 1
        quantity = "\(newQuantity)"

        try await updateStockQuantity(with: newQuantity)
    }

    func onTapUpdateStockQuantity() async throws {
        analytics.track(.inventoryUpdateManualQuantityTapped)
        guard let quantityDecimal = Decimal(string: quantity) else {
            throw UpdateInventoryError.nonSupportedQuantity
        }
        try await updateStockQuantity(with: quantityDecimal)
    }

    func onViewProductDetailsButtonTapped() {
        analytics.track(.inventoryUpdateViewProductDetailsTapped)
    }

    func onDismiss() {
        analytics.track(.inventoryUpdateDismissed)
    }

    func displayErrorNotice(_ productName: String) {
        notice =  Notice(title: Localization.errorNoticetitle,
                         message: String.localizedStringWithFormat(Localization.errorNoticeMessage, productName),
                         feedbackType: .error)
    }

    func onTapManageStock() async throws {
        do {
            isManageStockButtonLoading = true
            inventoryItem = try await inventoryItem.enableManageStock(stores: stores)
            analytics.track(.inventoryUpdateEnableManageStockSuccess)
            isManageStockButtonLoading = false
            refresh()
        } catch {
            isManageStockButtonLoading = false
            analytics.track(event: WooAnalyticsEvent(statName: .inventoryUpdateEnableManageStockFailure,
                                                     properties: [:],
                                                     error: error))
            throw UpdateInventoryError.generic
        }
    }

    func productDetailsView() -> some View {
        inventoryItem.detailsView()
    }
}

private extension UpdateProductInventoryViewModel {
    func updateStockQuantity(with newQuantity: Decimal) async throws {
        isPrimaryButtonLoading = true

        do {
            inventoryItem = try await inventoryItem.updateStockQuantity(with: newQuantity, stores: stores)
            onUpdatedInventory("\(newQuantity)")
            isPrimaryButtonLoading = false
            updateQuantityButtonMode = .increaseOnce
            analytics.track(.inventoryUpdateQuantityUpdateSuccess)
        }
        catch {
            isPrimaryButtonLoading = false
            analytics.track(.inventoryUpdateQuantityUpdateFailure)
            throw UpdateInventoryError.generic
        }
    }

    func refresh() {
        viewMode = inventoryItem.manageStock ? .stockCanBeManaged : .stockManagementNeedsToBeEnabled
        quantity = "\(inventoryItem.stockQuantity ?? 0)"
    }
}

private extension UpdateProductInventoryViewModel {
    struct Localization {
        static let errorNoticetitle = NSLocalizedString(
            "errorNoticeTitle.displayErrorNotice.UpdateProductInventoryViewModel",
            value: "Update Inventory Error",
            comment: "Title of the notice when inventory fails to be updated.")
        static let errorNoticeMessage = NSLocalizedString(
            "errorNoticeMessage.displayErrorNotice.UpdateProductInventoryViewModel",
            value: "There was an error updating %@. Please try again.",
            comment: "Message of the notice when inventory fails to be updated" +
            "Reads like: 'There was an error updating My Product Name. Please try again.'")
    }
}
