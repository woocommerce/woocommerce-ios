public protocol POSItem {
    var itemID: UUID { get }
}

public protocol POSItemProvider {
    func providePointOfSaleItems() -> [POSItem]
}
