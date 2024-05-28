import Foundation
import Networking

/// Helper to updates an `order` given an `OrderSyncInput` type.
///
public struct ProductInputTransformer {
    /// Type to help bundling  order Items parameters.
    ///
    struct OrderItemParameters {
        let quantity: Decimal
        let price: Decimal
        let discount: Decimal
        let productID: Int64
        let variationID: Int64?
        let baseSubtotal: Decimal?

        private var subTotalDecimal: Decimal {
            // Base subtotal has priority. Base subtotal and price can be different e.g. if the price includes tax (subtotal does not).
            (baseSubtotal ?? price) * quantity
        }

        var subtotal: String {
            "\(subTotalDecimal)"
        }
        var total: String {
            "\(subTotalDecimal - discount)"
        }
    }

    public enum UpdateOrDelete {
        case update
        case delete
    }

    /// Adds, deletes, or updates order items based on the given product input.
    /// When `shouldUpdateOrDeleteZeroQuantities` value is `.update`, items with `.zero` quantities will be updated instead of being deleted.
    ///
    public static func update(input: OrderSyncProductInput, on order: Order, shouldUpdateOrDeleteZeroQuantities: UpdateOrDelete) -> Order {
        // If the input's quantity is 0 or less, delete the item if required.
        guard input.quantity > 0 || shouldUpdateOrDeleteZeroQuantities == .update else {
            return remove(input: input, from: order)
        }

        // Add or update the order items with the new input.
        var items = order.items
        updateOrderItems(from: order, with: input, orderItems: &items)
        return order.copy(items: items)
    }

    /// Adds, deletes, or updates Order items based on the multiple given product inputs
    /// We receive an `[OrderSyncProductInput]` object as input, and must return an updated `Order`
    ///
    /// - Parameters:
    ///   - inputs: Array of product types the OrderSynchronizer supports
    ///   - order: Represents an Order entity.
    ///   - shouldUpdateOrDeleteZeroQuantities: When its value is `.update`, items with `.zero` quantities will be updated instead of being deleted.
    ///
    /// - Returns: An Order entity.
    public static func updateMultipleItems(with inputs: [OrderSyncProductInput], on order: Order, shouldUpdateOrDeleteZeroQuantities: UpdateOrDelete) -> Order {
        var updatedOrderItems = order.items

        for input in inputs {
            updateOrderItems(from: order, with: input, orderItems: &updatedOrderItems)
        }

        // If the input's quantity is 0 or less, delete the item if required.
        // We perform a second loop for deletions so we don't attempt to access to overflown indexes
        for input in inputs {
            guard input.quantity > 0 || shouldUpdateOrDeleteZeroQuantities == .update else {
                updatedOrderItems.removeAll(where: { $0.itemID == input.id })
                return order.copy(items: updatedOrderItems)
            }
        }

        return order.copy(items: updatedOrderItems)
    }

    /// Creates an array of OrderSyncProductInput that will be sent to the RemoteOrderSynchronizer when adding multiple products to an Order
    /// - Parameters:
    ///   - products: Selected products
    ///   - variations: Selected product variations
    /// - Returns: [OrderSyncProductInput]
    ///
    public static func productInputAdditionsToSync(
        order: Order,
        products: [Product],
        variations: [ProductVariation],
        productSelectorBundleConfigurationsByProductID: inout [Int64: [[BundledProductConfiguration]]],
        allProducts: Set<Product>,
        allProductVariations: Set<ProductVariation>
    ) -> [OrderSyncProductInput] {
        // TODO: move it back to app
        let itemsInOrder = syncExistingSelectedProducts(in: order, allProducts: allProducts, allProductVariations: allProductVariations)
        return productInputAdditionsToSync(
            orderItems: itemsInOrder,
            productsToSync: products,
            variations: variations,
            productSelectorBundleConfigurationsByProductID: &productSelectorBundleConfigurationsByProductID,
            allProducts: allProducts,
            allProductVariations: allProductVariations
        )
    }

    /// Creates an array of OrderSyncProductInput that will be sent to the RemoteOrderSynchronizer when adding multiple products to an Order
    /// - Parameters:
    ///   - products: Selected products
    ///   - variations: Selected product variations
    /// - Returns: [OrderSyncProductInput]
    ///
    public static func productInputAdditionsToSync(
        orderItems: [OrderItem],
        productsToSync products: [OrderSyncProductTypeProtocol],
        variations: [ProductVariation],
        productSelectorBundleConfigurationsByProductID: inout [Int64: [[BundledProductConfiguration]]],
        allProducts: Set<Product>,
        allProductVariations: Set<ProductVariation>
    ) -> [OrderSyncProductInput] {
        var productInputs: [OrderSyncProductInput] = []
        var productVariationInputs: [OrderSyncProductInput] = []

        let itemsInOrder = orderItems

        for product in products {
            // Only perform the operation if the product has not been already added to the existing Order
            if !itemsInOrder.contains(where: { $0.productID == product.productID && $0.parent == nil })
                || productSelectorBundleConfigurationsByProductID[product.productID]?.isEmpty == false {
                switch product.productType {
                    case .bundle:
                        if let bundleConfiguration = productSelectorBundleConfigurationsByProductID[product.productID]?.popFirst() {
                            productInputs.append(OrderSyncProductInput(product: .product(product), quantity: 1, bundleConfiguration: bundleConfiguration))
                        } else {
                            productInputs.append(OrderSyncProductInput(product: .product(product), quantity: 1))
                        }
                    default:
                        productInputs.append(OrderSyncProductInput(product: .product(product), quantity: 1))
                }
            }
        }
        productSelectorBundleConfigurationsByProductID = [:]

        for variation in variations {
            // Only perform the operation if the variation has not been already added to the existing Order
            if !itemsInOrder.contains(where: { $0.productOrVariationID == variation.productVariationID && $0.parent == nil }) {
                productVariationInputs.append(OrderSyncProductInput(product: .variation(variation), quantity: 1))
            }
        }

        return productInputs + productVariationInputs
    }

    /// Creates an array of OrderSyncProductInput that will be sent to the RemoteOrderSynchronizer when removing multiple products from an Order
    /// - Parameters:
    ///   - products: Represents a Product entity
    ///   - variations: Represents a ProductVariation entity
    /// - Returns: [OrderSyncProductInput]
    ///
    public static func productInputDeletionsToSync(order: Order,
                                                   products: [Product?],
                                                   variations: [ProductVariation?],
                                                   allProducts: Set<Product>,
                                                   allProductVariations: Set<ProductVariation>,
                                                   defaultDiscount: (OrderItem) -> Decimal) -> [OrderSyncProductInput] {
        // TODO: move it back to app
        let itemsInOrder = syncExistingSelectedProducts(in: order, allProducts: allProducts, allProductVariations: allProductVariations)
        return productInputDeletionsToSync(orderItems: itemsInOrder,
                                    productsToSync: products,
                                    variations: variations,
                                    allProducts: allProducts,
                                    allProductVariations: allProductVariations,
                                    defaultDiscount: defaultDiscount)
    }

    /// Creates an array of OrderSyncProductInput that will be sent to the RemoteOrderSynchronizer when removing multiple products from an Order
    /// - Parameters:
    ///   - products: Represents a Product entity
    ///   - variations: Represents a ProductVariation entity
    /// - Returns: [OrderSyncProductInput]
    ///
    public static func productInputDeletionsToSync(orderItems: [OrderItem],
                                                   productsToSync products: [OrderSyncProductTypeProtocol?],
                                                   variations: [ProductVariation?],
                                                   allProducts: Set<Product>,
                                                   allProductVariations: Set<ProductVariation>,
                                                   defaultDiscount: (OrderItem) -> Decimal) -> [OrderSyncProductInput] {
        var inputsToBeRemoved: [OrderSyncProductInput] = []

        let itemsInOrder = orderItems

        // Products to be removed from the Order
        let removeProducts = itemsInOrder.filter { item in
            return item.variationID == 0 && !products.contains(where: { $0?.productID == item.productID }) && item.parent == nil
        }

        // Variations to be removed from the Order
        let removeProductVariations = itemsInOrder.filter { item in
            return item.variationID != 0 && !variations.contains(where: { $0?.productVariationID == item.variationID })
        }

        let allOrderItemsToBeRemoved = removeProducts + removeProductVariations

        for item in allOrderItemsToBeRemoved {

            if let input = createUpdateProductInput(item: item, quantity: 0, allProducts: allProducts, allProductVariations: allProductVariations, defaultDiscount: defaultDiscount(item)) {
                inputsToBeRemoved.append(input)
            }

            // TODO: fix analytics
//            analytics.track(event: WooAnalyticsEvent.Orders.orderProductRemove(flow: flow.analyticsFlow))
        }

        return inputsToBeRemoved

    }

    /// Creates a new `OrderSyncProductInput` type meant to update an existing input from `OrderSynchronizer`
    /// If the referenced product can't be found, `nil` is returned.
    ///
    public static func createUpdateProductInput(item: OrderItem,
                                                childItems: [OrderItem] = [],
                                                quantity: Decimal,
                                                discount: Decimal? = nil,
                                                bundleConfiguration: [BundledProductConfiguration] = [],
                                                allProducts: Set<Product>,
                                                allProductVariations: Set<ProductVariation>,
                                                defaultDiscount: Decimal) -> OrderSyncProductInput? {
        // Finds the product or productVariation associated with the order item.
        let product: OrderSyncProductInput.ProductType? = {
            if item.variationID != 0, let variation = allProductVariations.first(where: { $0.productVariationID == item.variationID }) {
                return .variation(variation)
            }

            if let product = allProducts.first(where: { $0.productID == item.productID }) {
                return .product(product)
            }

            return nil
        }()

        guard let product = product else {
            DDLogError("⛔️ Product with ID: \(item.productID) not found.")
            return nil
        }

        // When updating a bundle product's quantity while there are no bundle configuration updates from the configuration form,
        // the bundle configuration needs to be populated in order for the quantity of child order items to be updated.
        // The bundle configuration is deduced from the product's bundle items, existing child order items, and the bundle order item itself.
        if case let .product(productValue) = product,
           productValue.productType == .bundle && item.quantity != quantity && bundleConfiguration.isEmpty && childItems.isNotEmpty {
            let bundleConfiguration: [BundledProductConfiguration] = productValue.bundledItems
                .compactMap { bundleItem -> BundledProductConfiguration? in
                    guard let existingOrderItem = childItems.first(where: { $0.productID == bundleItem.productID }) else {
                        return .init(bundledItemID: bundleItem.bundledItemID,
                                     productOrVariation: .product(id: bundleItem.productID),
                                     quantity: 0,
                                     isOptionalAndSelected: false)
                    }
                    let attributes = existingOrderItem.attributes
                        .map { ProductVariationAttribute(id: $0.metaID, name: $0.name, option: $0.value) }
                    let productOrVariation: BundledProductConfiguration.ProductOrVariation = existingOrderItem.variationID == 0 ?
                        .product(id: existingOrderItem.productID): .variation(productID: existingOrderItem.productID,
                                                                              variationID: existingOrderItem.variationID,
                                                                              attributes: attributes)
                    // The quantity per bundle: as a buggy behavior in Pe5pgL-3Vd-p2#quantity-of-bundle-child-order-items, the child item quantity
                    // can either by multiplied by the bundle quantity or not. To encounter for the edge case, the quantity is only divided by
                    // the bundle quantity if the child item has at least the same quantity as the bundle.
                    let quantity = existingOrderItem.quantity >= item.quantity ?
                    existingOrderItem.quantity * 1.0 / item.quantity: existingOrderItem.quantity
                    return .init(bundledItemID: bundleItem.bundledItemID,
                                 productOrVariation: productOrVariation,
                                 quantity: quantity,
                                 isOptionalAndSelected: bundleItem.isOptional ? true: nil)
                }
            return OrderSyncProductInput(id: item.itemID,
                                         product: product,
                                         quantity: quantity,
                                         discount: discount ?? defaultDiscount,
                                         baseSubtotal: baseSubtotal(on: item),
                                         bundleConfiguration: bundleConfiguration)
        }

        // Return a new input with the new quantity but with the same item id to properly reference the update.
        return OrderSyncProductInput(id: item.itemID,
                                     product: product,
                                     quantity: quantity,
                                     discount: discount ?? defaultDiscount,
                                     baseSubtotal: baseSubtotal(on: item),
                                     bundleConfiguration: bundleConfiguration)
    }
}

// MARK: ProductInputTransformer helper methods
//
private extension ProductInputTransformer {
    /// Creates, or updates existing `OrderItems` of a given `Order` with any `OrderSyncProductInput` update
    ///
    /// - Parameters:
    ///   - order: Represents an Order entity.
    ///   - input: Types of products the synchronizer supports
    ///   - updatedOrderItems: An array of `[OrderItem]` entities
    ///
    static func updateOrderItems(from order: Order, with input: OrderSyncProductInput, orderItems updatedOrderItems: inout [OrderItem]) {
        let newItem = createOrderItem(using: input)

        if let itemIndex = order.items.firstIndex(where: { $0.itemID == input.id }) {
            updatedOrderItems[itemIndex] = newItem
        } else {
            updatedOrderItems.append(newItem)
        }
    }

    /// Updates the `OrderItems` array with `OrderSyncProductInput`.
    /// Uses the same implementation as `update()` but returns an array of OrderItems instead,
    /// rather than aggregating them into the Order
    ///
    /// - Parameters:
    ///   - input: Types of products the synchronizer supports
    ///   - order: Represents an Order entity.
    ///   - shouldUpdateOrDeleteZeroQuantities: When its value is `.update`, items with `.zero` quantities will be updated instead of being deleted.
    ///
    /// - Returns: An array of Order Item entities
    private static func updateOrderItems(from input: OrderSyncProductInput, order: Order, shouldUpdateOrDeleteZeroQuantities: UpdateOrDelete) -> [OrderItem] {
        // If the input's quantity is 0 or less, delete the item if required.
        guard input.quantity > 0 || shouldUpdateOrDeleteZeroQuantities == .update else {
            return remove(input: input, from: order).items
        }

        // Adds or updates the Order items with the new input:
        var updatedOrderItems = order.items
        updateOrderItems(from: order, with: input, orderItems: &updatedOrderItems)

        return updatedOrderItems
    }

    /// Removes an order item from an order when the `item.itemID` matches the `input.id`.
    ///
    private static func remove(input: OrderSyncProductInput, from order: Order) -> Order {
        var items = order.items
        items.removeAll { $0.itemID == input.id }
        return order.copy(items: items)
    }

    /// Creates and order item by using the `input.id` as the `item.itemID`.
    ///
    private static func createOrderItem(using input: OrderSyncProductInput) -> OrderItem {
        let parameters: OrderItemParameters = {
            switch input.product {
            case .product(let product):
                let price: Decimal = Decimal(string: product.price) ?? .zero
                return OrderItemParameters(quantity: input.quantity,
                                           price: price,
                                           discount: input.discount,
                                           productID: product.productID,
                                           variationID: nil,
                                           baseSubtotal: input.baseSubtotal)
            case .variation(let variation):
                let price: Decimal = Decimal(string: variation.price) ?? .zero
                return OrderItemParameters(quantity: input.quantity,
                                           price: price,
                                           discount: input.discount,
                                           productID: variation.productID,
                                           variationID: variation.productVariationID,
                                           baseSubtotal: input.baseSubtotal)
            }
        }()

        return OrderItem(itemID: input.id,
                         name: "",
                         productID: parameters.productID,
                         variationID: parameters.variationID ?? 0,
                         quantity: parameters.quantity,
                         price: parameters.price as NSDecimalNumber,
                         sku: nil,
                         subtotal: parameters.subtotal,
                         subtotalTax: "",
                         taxClass: "",
                         taxes: [],
                         total: parameters.total,
                         totalTax: "",
                         attributes: [],
                         addOns: [],
                         parent: nil,
                         bundleConfiguration: input.bundleConfiguration.map {
            switch $0.productOrVariation {
                case let .product(productID):
                    return .init(bundledItemID: $0.bundledItemID,
                                 productID: productID,
                                 quantity: $0.quantity,
                                 isOptionalAndSelected: $0.isOptionalAndSelected,
                                 variationID: nil,
                                 variationAttributes: nil)
                case let .variation(productID, variationID, attributes):
                    return .init(bundledItemID: $0.bundledItemID,
                                 productID: productID,
                                 quantity: $0.quantity,
                                 isOptionalAndSelected: $0.isOptionalAndSelected,
                                 variationID: variationID,
                                 variationAttributes: attributes)
            }
        })
    }

    /// Checks the latest Order sync, and returns the current items that are in the Order
    ///
    private static func syncExistingSelectedProducts(in order: Order,
                                                     allProducts: Set<Product>,
                                                     allProductVariations: Set<ProductVariation>) -> [OrderItem] {
        var itemsInOrder: [OrderItem] = []
        let _ = order.items.map { item in
            if item.variationID != 0 {
                if let _ = allProductVariations.first(where: { $0.productVariationID == item.variationID }) {
                    itemsInOrder.append(item)
                }
            } else {
                if let _ = allProducts.first(where: { $0.productID == item.productID }) {
                    itemsInOrder.append(item)
                }
            }
        }
        return itemsInOrder
    }

    /// Calculates the subtotal of a single quantity of an item
    ///
    static func baseSubtotal(on item: OrderItem) -> Decimal? {
        guard let itemSubtotal = Decimal(string: item.subtotal) else {
            return nil
        }

        return itemSubtotal / item.quantity
    }
}

// MARK: - OrderItem Helper Methods
//
extension OrderItem {
    /// Returns the variant if it exists
    ///
    var productOrVariationID: Int64 {
        if variationID == 0 {
            return productID
        }

        return variationID
    }
}

// MARK: - Array Helpers
//
extension Array {
    /// Removes and returns the first element in the array. If any!
    ///
    mutating func popFirst() -> Element? {
        guard isEmpty == false else {
            return nil
        }

        return removeFirst()
    }

    /// A Boolean value indicating whether a collection is not empty.
    var isNotEmpty: Bool {
        return !isEmpty
    }

    /// A Bool indicating if the collection has at least two elements
    var containsMoreThanOne: Bool {
        return count > 1
    }
}
