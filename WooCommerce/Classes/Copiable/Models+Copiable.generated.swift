// Generated using Sourcery 0.18.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Networking


extension AggregateOrderItem {
    func copy(
        productID: CopiableProp<Int64> = .copy,
        variationID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        price: NullableCopiableProp<NSDecimalNumber> = .copy,
        quantity: CopiableProp<Decimal> = .copy,
        sku: NullableCopiableProp<String> = .copy,
        total: NullableCopiableProp<NSDecimalNumber> = .copy,
        imageURL: NullableCopiableProp<URL> = .copy,
        attributes: CopiableProp<[OrderItemAttribute]> = .copy
    ) -> AggregateOrderItem {
        let productID = productID ?? self.productID
        let variationID = variationID ?? self.variationID
        let name = name ?? self.name
        let price = price ?? self.price
        let quantity = quantity ?? self.quantity
        let sku = sku ?? self.sku
        let total = total ?? self.total
        let imageURL = imageURL ?? self.imageURL
        let attributes = attributes ?? self.attributes

        return AggregateOrderItem(
            productID: productID,
            variationID: variationID,
            name: name,
            price: price,
            quantity: quantity,
            sku: sku,
            total: total,
            imageURL: imageURL,
            attributes: attributes
        )
    }
}
