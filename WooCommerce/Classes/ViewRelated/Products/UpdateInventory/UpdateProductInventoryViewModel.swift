import Combine
import Yosemite

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

final class UpdateProductInventoryViewModel: ObservableObject {
    var inventoryItem: InventoryItem
    private let stores: StoresManager

    init(inventoryItem: InventoryItem,
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        self.inventoryItem = inventoryItem
        self.stores = stores

        quantity = inventoryItem.stockQuantity?.formatted() ?? ""

        Task { @MainActor in
            name = try await inventoryItem.retrieveName(with: stores, siteID: siteID)
        }
    }

    @Published var quantity: String = ""
    @Published var name: String = Localization.productNamePlaceholder

    var sku: String {
        inventoryItem.sku ?? ""
    }

    var imageURL: URL? {
        inventoryItem.imageURL
    }

    func onTapUpdateStockQuantity() async {
        guard let quantityDecimal = Decimal(string: quantity) else {
            return
        }

        // TODO: Handle error
        try? await inventoryItem.updateStockQuantity(with: quantityDecimal, stores: stores)
    }
}

extension UpdateProductInventoryViewModel {
    enum Localization {
        static let productNamePlaceholder = NSLocalizedString("updateProductInventoryViewModel.productName.placeholder",
                                                              value: "Product Name",
                                                              comment: "Placeholder of the product name title.")
    }
}
