public protocol OrderSyncProductTypeProtocol {
    var price: String { get }
    var productID: Int64 { get }
    var productType: ProductType { get }
    var bundledItems: [ProductBundleItem] { get }
}

extension Product: OrderSyncProductTypeProtocol {}

/// Product input for an `OrderSynchronizer` type.
///
public struct OrderSyncProductInput {
    public init(id: Int64 = .zero,
                product: OrderSyncProductInput.ProductType,
                quantity: Decimal,
                discount: Decimal = .zero,
                baseSubtotal: Decimal? = nil,
                bundleConfiguration: [BundledProductConfiguration] = []) {
        self.id = id
        self.product = product
        self.quantity = quantity
        self.discount = discount
        self.baseSubtotal = baseSubtotal
        self.bundleConfiguration = bundleConfiguration
    }

    /// Types of products the synchronizer supports
    ///
    public enum ProductType {
        case product(OrderSyncProductTypeProtocol)
        case variation(ProductVariation)
    }
    public var id: Int64 = .zero
    let product: ProductType
    let quantity: Decimal
    var discount: Decimal = .zero
    public let bundleConfiguration: [BundledProductConfiguration]

    /// The subtotal of one element. This might be different than the product price, if the price includes tax (subtotal does not).
    ///
    var baseSubtotal: Decimal? = nil

    public func updating(id: Int64) -> OrderSyncProductInput {
        .init(id: id,
              product: self.product,
              quantity: self.quantity,
              discount: discount,
              baseSubtotal: self.baseSubtotal,
              bundleConfiguration: bundleConfiguration)
    }
}
