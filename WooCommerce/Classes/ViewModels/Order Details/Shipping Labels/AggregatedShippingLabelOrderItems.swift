import Yosemite

/// Aggregates the order items included in a shipping label for UI display given the currently available `OrderItem`s, `Product`s,
/// and `ProductVariation`s from an `Order`.
/// Because the shipping label API response only returns an array of product names and optional product IDs based on the plugin version
/// (product IDs are only available in WooCommerce Shipping & Tax v1.24.1+), this struct generates a dictionary that maps a shipping
/// label to an array of `AggregateOrderItem` for UI display.
/// An order's current order items, products, and product variations are also provided since we want to display the order item at
/// the time of order creation in case the product/variation changes over time.
struct AggregatedShippingLabelOrderItems {
    private let currencyFormatter: CurrencyFormatter

    private var orderItemsByShippingLabelID: [Int64: [AggregateOrderItem]] = [:]

    /// - Parameters:
    ///   - shippingLabels: An array of shipping labels for an order.
    ///   - orderItems: An array of items for an order. Used to show the most accurate information for an order in case
    ///     the product/variation has changed after order creation.
    ///   - products: An array of products for an order that have been fetched.
    ///   - productVariations: An array of product variations for an order that have been fetched.
    ///   - currencyFormatter: Used to convert a product/variation's price string to number.
    init(shippingLabels: [ShippingLabel],
         orderItems: [OrderItem],
         products: [Product],
         productVariations: [ProductVariation],
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.currencyFormatter = currencyFormatter

        aggregateProductsToOrderItems(shippingLabels: shippingLabels, orderItems: orderItems, products: products, productVariations: productVariations)
    }

    static let empty: AggregatedShippingLabelOrderItems = .init(shippingLabels: [], orderItems: [], products: [], productVariations: [])

    /// Returns an array of order items for a shipping label.
    func orderItems(of shippingLabel: ShippingLabel) -> [AggregateOrderItem] {
        orderItemsByShippingLabelID[shippingLabel.shippingLabelID] ?? []
    }

    /// Returns an order item for a shipping label given an index, if available. Otherwise, nil is returned.
    func orderItem(of shippingLabel: ShippingLabel, at index: Int) -> AggregateOrderItem? {
        orderItems(of: shippingLabel)[safe: index]
    }

    /// Returns an array of order items from all of the given non-refunded shipping labels.
    func orderItemsOfNonRefundedShippingLabels(_ shippingLabels: [ShippingLabel]) -> [AggregateOrderItem] {
        shippingLabels.nonRefunded.flatMap { orderItems(of: $0) }
    }
}

private extension AggregatedShippingLabelOrderItems {
    mutating func aggregateProductsToOrderItems(shippingLabels: [ShippingLabel],
                                                orderItems: [OrderItem],
                                                products: [Product],
                                                productVariations: [ProductVariation]) {
        orderItemsByShippingLabelID = shippingLabels.reduce(into: [Int64: [AggregateOrderItem]]()) { result, shippingLabel in
            result[shippingLabel.shippingLabelID] = aggregateProductsToOrderItems(shippingLabel: shippingLabel,
                                                                                  orderItems: orderItems,
                                                                                  products: products,
                                                                                  productVariations: productVariations)
        }
    }

    func aggregateProductsToOrderItems(shippingLabel: ShippingLabel,
                                       orderItems: [OrderItem],
                                       products: [Product],
                                       productVariations: [ProductVariation]) -> [AggregateOrderItem] {
        // ShippingLabel's `productNames` is always available, but `productIDs` is only available in WooCommerce Shipping & Tax v1.24.1+.
        // Here we map a ShippingLabel's `productNames` to `ProductInformation` with an optional product ID at the corresponding index.
        let productInfoArray = shippingLabel.productNames.enumerated().map { index, productName in
            ProductInformation(id: shippingLabel.productIDs[safe: index], name: productName)
        }

        // Generates a dictionary that maps a `ProductInformation` to the number of times (quantity) in a shipping label.
        let countsByProductInformation = productInfoArray.reduce(into: [ProductInformation: Int]()) { result, productInfo in
            result[productInfo] = (result[productInfo] ?? 0) + 1
        }

        // In the API, if a product has quantity higher than 1, it is repeated in the `productNames`/`productIDs` array.
        // Note that decimal quantity might have unexpected behavior given the current API design.
        let uniqueProductInfoArray = productInfoArray.removingDuplicates()

        // Maps each unique `ProductInformation` to an `AggregateOrderItem` given available order items, products, and product variations.
        return uniqueProductInfoArray
            .map { productInfo -> AggregateOrderItem in
                let model = orderItemModel(productInfo: productInfo,
                                           orderItems: orderItems,
                                           products: products,
                                           productVariations: productVariations)
                let quantity = countsByProductInformation[productInfo] ?? 0
                return orderItem(from: model, quantity: quantity)
            }
    }

    func orderItemModel(productInfo: ProductInformation,
                        orderItems: [OrderItem],
                        products: [Product],
                        productVariations: [ProductVariation]) -> OrderItemModel {
        guard let productID = productInfo.id else {
            return .productName(name: productInfo.name)
        }

        if let product = lookUpProduct(by: productID, products: products) {
            let orderItem = orderItems.first(where: { $0.productID == productID })
            return .product(product: product, orderItem: orderItem, name: productInfo.name)
        } else if let productVariation = lookUpProductVariation(by: productID, productVariations: productVariations) {
            let orderItem = orderItems.first(where: { $0.variationID == productID })
            return .productVariation(productVariation: productVariation, orderItem: orderItem, name: productInfo.name)
        } else {
            return .productName(name: productInfo.name)
        }
    }

    func orderItem(from model: OrderItemModel, quantity: Int) -> AggregateOrderItem {
        switch model {
        case .productName(let name):
            return .init(productID: 0, variationID: 0, name: name, price: nil, quantity: 0, sku: nil, total: nil, attributes: [])
        case .product(let product, let orderItem, let name):
            let productName = orderItem?.name ?? name
            let price = orderItem?.price ??
                currencyFormatter.convertToDecimal(from: product.price) ?? 0
            let totalPrice = price.multiplying(by: .init(decimal: Decimal(quantity)))
            return .init(productID: product.productID,
                         variationID: 0,
                         name: productName,
                         price: price,
                         quantity: Decimal(quantity),
                         sku: orderItem?.sku ?? product.sku,
                         total: totalPrice,
                         imageURL: URL(string: product.images.first?.src ?? ""),
                         attributes: orderItem?.attributes ?? [])
        case .productVariation(let variation, let orderItem, let name):
            let productName = orderItem?.name ?? name
            let price = orderItem?.price ??
                currencyFormatter.convertToDecimal(from: variation.price) ?? 0
            let totalPrice = price.multiplying(by: .init(decimal: Decimal(quantity)))
            return .init(productID: variation.productID,
                         variationID: variation.productVariationID,
                         name: productName,
                         price: price,
                         quantity: Decimal(quantity),
                         sku: orderItem?.sku ?? variation.sku,
                         total: totalPrice,
                         imageURL: URL(string: variation.image?.src ?? ""),
                         attributes: orderItem?.attributes ?? [])
        }
    }

    func lookUpProduct(by productID: Int64, products: [Product]) -> Product? {
        products.first(where: { $0.productID == productID })
    }

    func lookUpProductVariation(by productID: Int64, productVariations: [ProductVariation]) -> ProductVariation? {
        productVariations.first(where: { $0.productVariationID == productID })
    }
}

private extension AggregatedShippingLabelOrderItems {
    /// Information about a product from `ShippingLabel`. The product ID is only available in WooCommerce Shipping & Tax v1.24.1+.
    struct ProductInformation: Equatable, Hashable {
        let id: Int64?
        let name: String
    }

    /// The underlying model for an order item.
    enum OrderItemModel {
        case productName(name: String)
        case product(product: Product, orderItem: OrderItem?, name: String)
        case productVariation(productVariation: ProductVariation, orderItem: OrderItem?, name: String)
    }
}
