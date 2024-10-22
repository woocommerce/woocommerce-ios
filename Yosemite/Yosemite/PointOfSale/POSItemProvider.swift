public protocol POSItem {
    var itemID: UUID { get }
    var productID: Int64 { get }
    var name: String { get }
    var price: String { get }
    var formattedPrice: String { get }
    var itemCategories: [String] { get }
    var productImageSource: String? { get }
    var productType: ProductType { get }
}

extension POSItem {
    // Equatable conformance
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.itemID == rhs.itemID &&
        lhs.productID == rhs.productID &&
        lhs.name == rhs.name &&
        lhs.price == rhs.price &&
        lhs.formattedPrice == rhs.formattedPrice &&
        lhs.itemCategories == rhs.itemCategories &&
        lhs.productImageSource == rhs.productImageSource &&
        lhs.productType == rhs.productType
    }
}

public protocol POSItemProvider {
    func providePointOfSaleItems(pageNumber: Int) async throws -> [POSItem]
}

// Default implementation for convenience, so we do not need to pass the first page explicitely
// if no pageNumber is given.
extension POSItemProvider {
    func providePointOfSaleItems(pageNumber: Int = 1) async throws -> [POSItem] {
        try await providePointOfSaleItems(pageNumber: 1)
    }
}
