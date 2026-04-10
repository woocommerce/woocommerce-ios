import Foundation
import Networking

public protocol OrderSyncProductTypeProtocol: Hashable {
    var price: String { get }
    var productID: Int64 { get }
    var productType: ProductType { get }
    var bundledItems: [ProductBundleItem] { get }

    func isEqual(to: any OrderSyncProductTypeProtocol) -> Bool
}

extension Product: OrderSyncProductTypeProtocol {}

public extension OrderSyncProductTypeProtocol where Self: Equatable {
    func isEqual(to other: any OrderSyncProductTypeProtocol) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}

public protocol OrderSyncProductVariationTypeProtocol: Hashable {
    var price: String { get }
    var productVariationID: Int64 { get }
    var productID: Int64 { get }

    func isEqual(to: any OrderSyncProductVariationTypeProtocol) -> Bool
}

extension ProductVariation: OrderSyncProductVariationTypeProtocol {}

public extension OrderSyncProductVariationTypeProtocol where Self: Equatable {
    func isEqual(to other: any OrderSyncProductVariationTypeProtocol) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}

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
    public enum ProductType: Hashable {
        case product(any OrderSyncProductTypeProtocol)
        case variation(any OrderSyncProductVariationTypeProtocol)

        public func hash(into hasher: inout Hasher) {
            switch self {
            case .product(let product):
                hasher.combine("productType-product")
                hasher.combine(product)
            case .variation(let variation):
                hasher.combine("productType-variation")
                hasher.combine(variation)
            }
        }

        public static func == (lhs: OrderSyncProductInput.ProductType, rhs: OrderSyncProductInput.ProductType) -> Bool {
            switch (lhs, rhs) {
            case (.product(let lhsProduct), .product(let rhsProduct)):
                return lhsProduct.isEqual(to: rhsProduct)
            case (.variation(let lhsVariation), .variation(let rhsVariation)):
                return lhsVariation.isEqual(to: rhsVariation)
            default:
                return false
            }
        }
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
