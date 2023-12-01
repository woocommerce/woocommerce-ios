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
}

final class UpdateProductInventoryViewModel: ObservableObject {
    enum UpdateQuantityButtonMode {
        case increaseOnce
        case customQuantity
    }

    let inventoryItem: InventoryItem

    init(inventoryItem: InventoryItem,
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        self.inventoryItem = inventoryItem

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

    @Published var enableQuantityButton: Bool = true
    @Published var showLoadingName: Bool = true
    @Published var name: String = ""
    @Published var updateQuantityButtonMode: UpdateQuantityButtonMode = .increaseOnce

    var sku: String {
        inventoryItem.sku ?? ""
    }

    var imageURL: URL? {
        inventoryItem.imageURL
    }
}
