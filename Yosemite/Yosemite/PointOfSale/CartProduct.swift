
public struct CartProduct {
    public let id: UUID
    public let product: POSItem
    public let quantity: Int

    public init(id: UUID, product: POSItem, quantity: Int) {
        self.id = id
        self.product = product
        self.quantity = quantity
    }
}
