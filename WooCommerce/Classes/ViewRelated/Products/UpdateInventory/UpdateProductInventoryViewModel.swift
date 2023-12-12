import Combine
import Yosemite

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
    func updateStockQuantity(with newQuantity: Decimal, stores: StoresManager) async throws
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

    func updateStockQuantity(with newQuantity: Decimal, stores: StoresManager) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let newProduct = copy(stockQuantity: newQuantity)

            let action = ProductAction.updateProduct(product: newProduct) { result in
                switch result {
                case .success(_):
                    continuation.resume(with: .success(()))
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

    func updateStockQuantity(with newQuantity: Decimal, stores: StoresManager) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let newProductVaiation = copy(stockQuantity: newQuantity)

            let action = ProductVariationAction.updateProductVariation(productVariation: newProductVaiation) { result in
                switch result {
                case .success(_):
                    continuation.resume(with: .success(()))
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

    let inventoryItem: InventoryItem
    private let stores: StoresManager

    var onUpdatedInventory: ((String) -> ())

    init(inventoryItem: InventoryItem,
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         onUpdatedInventory: @escaping ((String) -> ())) {
        self.inventoryItem = inventoryItem
        self.stores = stores
        self.onUpdatedInventory = onUpdatedInventory

        quantity = inventoryItem.stockQuantity?.formatted() ?? ""

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
            updateQuantityButtonMode = decimalValue == inventoryItem.stockQuantity ? .increaseOnce : .customQuantity
        }
    }

    @Published var isPrimaryButtonLoading: Bool = false
    @Published var enableQuantityButton: Bool = true
    @Published var showLoadingName: Bool = true
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
        guard let quantityDecimal = Decimal(string: quantity) else {
            return
        }

        let newQuantity = quantityDecimal + 1
        quantity = newQuantity.formatted()

        do {
            try await updateStockQuantity(with: newQuantity)
        } catch {
            throw UpdateInventoryError.generic
        }
    }

    func onTapUpdateStockQuantity() async throws {
        guard let quantityDecimal = Decimal(string: quantity) else {
            throw UpdateInventoryError.nonSupportedQuantity
        }

        do {
            try await updateStockQuantity(with: quantityDecimal)
        } catch {
            throw UpdateInventoryError.generic
        }
    }

    func displayErrorNotice(_ productName: String) {
        notice =  Notice(title: Localization.errorNoticetitle,
                         message: String.localizedStringWithFormat(Localization.errorNoticeMessage, productName),
                         feedbackType: .error)
    }
}

private extension UpdateProductInventoryViewModel {
    func updateStockQuantity(with newQuantity: Decimal) async throws {
        isPrimaryButtonLoading = true

        do {
            try await inventoryItem.updateStockQuantity(with: newQuantity, stores: stores)
            onUpdatedInventory(newQuantity.formatted())
        } catch {
            isPrimaryButtonLoading = false
            throw UpdateInventoryError.generic
        }

        isPrimaryButtonLoading = false
        updateQuantityButtonMode = .increaseOnce
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
