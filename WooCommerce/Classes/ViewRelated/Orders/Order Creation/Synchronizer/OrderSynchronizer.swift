import Foundation
import Yosemite
import Combine

/// Possible states of an `OrderSynchronizer` type.
///
enum OrderSyncState {
    case syncing(blocking: Bool)
    case synced
    case error(Error, usesGiftCard: Bool)
}

/// Product input for an `OrderSynchronizer` type.
///
struct OrderSyncProductInput {
    init(id: Int64 = .zero,
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
    enum ProductType {
        case product(Product)
        case variation(ProductVariation)
    }
    var id: Int64 = .zero
    let product: ProductType
    let quantity: Decimal
    var discount: Decimal = .zero
    let bundleConfiguration: [BundledProductConfiguration]

    /// The subtotal of one element. This might be different than the product price, if the price includes tax (subtotal does not).
    ///
    var baseSubtotal: Decimal? = nil

    func updating(id: Int64) -> OrderSyncProductInput {
        .init(id: id,
              product: self.product,
              quantity: self.quantity,
              discount: discount,
              baseSubtotal: self.baseSubtotal,
              bundleConfiguration: bundleConfiguration)
    }
}

/// Addresses input for an `OrderSynchronizer` type.
///
struct OrderSyncAddressesInput {
    let billing: Address?
    let shipping: Address?
}

/// A type that  receives "supported" order properties and keeps it synced against another source.
///
protocol OrderSynchronizer {

    // MARK: Outputs

    /// Latest order sync state.
    ///
    var state: OrderSyncState { get }

    /// Order Sync State Publisher.
    ///
    var statePublisher: Published<OrderSyncState>.Publisher { get }

    /// Latest order to be synced or that is synced.
    ///
    var order: Order { get }

    var inFlightRequest: Order? { get }

    /// Publisher for the order toe be synced or that is synced.
    ///
    var orderPublisher: Published<Order>.Publisher { get }

    /// Gift card code to apply to the order.
    var giftCardToApply: String? { get }

    /// Publisher for the gift card code to apply to the order.
    var giftCardToApplyPublisher: Published<String?>.Publisher { get }

    // MARK: Inputs

    /// Changes the underlaying order status.
    /// This property is not synched remotely until `commitAllChanges` method is invoked.
    ///
    var setStatus: PassthroughSubject<OrderStatusEnum, Never> { get }

    /// Sets a product with it's quantity.
    /// Set a `zero` quantity to remove a product.
    ///
    var setProduct: PassthroughSubject<OrderSyncProductInput, Never> { get }

    /// Sets multiple products with their quantities.
    ///
    var setProducts: PassthroughSubject<[OrderSyncProductInput], Never> { get }

    /// Sets or removes the order shipping & billing addresses.
    ///
    var setAddresses: PassthroughSubject<OrderSyncAddressesInput?, Never> { get }

    /// Sets or removes a shipping line.
    ///
    var setShipping: PassthroughSubject<ShippingLine?, Never> { get }

    /// Adds a fee to the order.
    ///
    var addFee: PassthroughSubject<OrderFeeLine, Never> { get }

    /// Removes the fee from the order.
    ///
    var removeFee: PassthroughSubject<OrderFeeLine, Never> { get }

    /// Updates the fee with the given fee Id.
    ///
    var updateFee: PassthroughSubject<OrderFeeLine, Never> { get }

    /// Adds an order coupon.
    ///
    var addCoupon: PassthroughSubject<String, Never> { get }

    /// Removes an order coupon.
    ///
    var removeCoupon: PassthroughSubject<String, Never> { get }

    /// Sets the gift card applied to the order.
    var setGiftCard: PassthroughSubject<String?, Never> { get }

    /// Sets or removes an order customer note.
    ///
    var setNote: PassthroughSubject<String?, Never> { get }

    /// Trigger to retry a remote sync.
    ///
    var retryTrigger: PassthroughSubject<Void, Never> { get }

    /// Commits all order changes to the remote source. State needs to be in `.synced` to initiate work.
    ///
    func commitAllChanges(onCompletion: @escaping (Result<Order, Error>, _ usesGiftCard: Bool) -> Void)
}
