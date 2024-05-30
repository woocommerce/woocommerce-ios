
public struct CartProduct {
    public let id: UUID
    public let product: POSProduct
    public let quantity: Int

    public init(id: UUID, product: POSProduct, quantity: Int) {
        self.id = id
        self.product = product
        self.quantity = quantity
    }
}
