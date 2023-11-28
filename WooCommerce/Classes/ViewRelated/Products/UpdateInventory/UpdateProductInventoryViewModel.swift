import Combine
import Yosemite

typealias InventoryProductTypeAlias = SKUSearchResult

protocol InventoryItem {
    var manageStock: Bool { get }
    var stockQuantity: Decimal? { get }
    var sku: String? { get }
    var name: String { get }
    var imageURL: URL? { get }
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

extension Product: InventoryItem {}
extension ProductVariation: InventoryItem {
    var name: String {
        attributes.map { $0.name }.joined(separator: " • ")
    }
}

final class UpdateProductInventoryViewModel: ObservableObject {
    let inventoryItem: InventoryItem

    init(inventoryItem: InventoryItem) {
        self.inventoryItem = inventoryItem

        quantity = inventoryItem.stockQuantity?.formatted() ?? ""
    }

    @Published var quantity: String = ""
    var name: String {
        inventoryItem.name
    }

    var sku: String {
        inventoryItem.sku ?? ""
    }

    var imageURL: URL? {
        inventoryItem.imageURL
    }
}
