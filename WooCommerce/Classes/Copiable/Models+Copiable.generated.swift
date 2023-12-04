// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import Foundation
import Yosemite


extension WooCommerce.AggregateOrderItem {
    func copy(
        itemID: CopiableProp<String> = .copy,
        productID: CopiableProp<Int64> = .copy,
        variationID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        price: NullableCopiableProp<NSDecimalNumber> = .copy,
        quantity: CopiableProp<Decimal> = .copy,
        sku: NullableCopiableProp<String> = .copy,
        total: NullableCopiableProp<NSDecimalNumber> = .copy,
        imageURL: NullableCopiableProp<URL> = .copy,
        attributes: CopiableProp<[OrderItemAttribute]> = .copy,
        addOns: CopiableProp<[OrderItemProductAddOn]> = .copy,
        parent: NullableCopiableProp<Int64> = .copy
    ) -> WooCommerce.AggregateOrderItem {
        let itemID = itemID ?? self.itemID
        let productID = productID ?? self.productID
        let variationID = variationID ?? self.variationID
        let name = name ?? self.name
        let price = price ?? self.price
        let quantity = quantity ?? self.quantity
        let sku = sku ?? self.sku
        let total = total ?? self.total
        let imageURL = imageURL ?? self.imageURL
        let attributes = attributes ?? self.attributes
        let addOns = addOns ?? self.addOns
        let parent = parent ?? self.parent

        return WooCommerce.AggregateOrderItem(
            itemID: itemID,
            productID: productID,
            variationID: variationID,
            name: name,
            price: price,
            quantity: quantity,
            sku: sku,
            total: total,
            imageURL: imageURL,
            attributes: attributes,
            addOns: addOns,
            parent: parent
        )
    }
}

extension WooCommerce.ShippingLabelSelectedRate {
    func copy(
        packageID: CopiableProp<String> = .copy,
        rate: CopiableProp<ShippingLabelCarrierRate> = .copy,
        signatureRate: NullableCopiableProp<ShippingLabelCarrierRate> = .copy,
        adultSignatureRate: NullableCopiableProp<ShippingLabelCarrierRate> = .copy
    ) -> WooCommerce.ShippingLabelSelectedRate {
        let packageID = packageID ?? self.packageID
        let rate = rate ?? self.rate
        let signatureRate = signatureRate ?? self.signatureRate
        let adultSignatureRate = adultSignatureRate ?? self.adultSignatureRate

        return WooCommerce.ShippingLabelSelectedRate(
            packageID: packageID,
            rate: rate,
            signatureRate: signatureRate,
            adultSignatureRate: adultSignatureRate
        )
    }
}
