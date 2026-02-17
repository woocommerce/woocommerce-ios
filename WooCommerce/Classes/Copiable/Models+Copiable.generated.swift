// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import Foundation
import Yosemite

// swiftlint:disable line_length

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

extension WooCommerce.ProductListItem {
    func copy(
        siteID: CopiableProp<Int64> = .copy,
        productID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        productTypeKey: CopiableProp<String> = .copy,
        statusKey: CopiableProp<String> = .copy,
        sku: NullableCopiableProp<String> = .copy,
        manageStock: CopiableProp<Bool> = .copy,
        stockQuantity: NullableCopiableProp<Decimal> = .copy,
        stockStatusKey: CopiableProp<String> = .copy,
        imageURL: NullableCopiableProp<URL> = .copy,
        variations: CopiableProp<[Int64]> = .copy,
        bundleStockStatus: NullableCopiableProp<ProductStockStatus> = .copy,
        bundleStockQuantity: NullableCopiableProp<Int64> = .copy
    ) -> WooCommerce.ProductListItem {
        let siteID = siteID ?? self.siteID
        let productID = productID ?? self.productID
        let name = name ?? self.name
        let productTypeKey = productTypeKey ?? self.productTypeKey
        let statusKey = statusKey ?? self.statusKey
        let sku = sku ?? self.sku
        let manageStock = manageStock ?? self.manageStock
        let stockQuantity = stockQuantity ?? self.stockQuantity
        let stockStatusKey = stockStatusKey ?? self.stockStatusKey
        let imageURL = imageURL ?? self.imageURL
        let variations = variations ?? self.variations
        let bundleStockStatus = bundleStockStatus ?? self.bundleStockStatus
        let bundleStockQuantity = bundleStockQuantity ?? self.bundleStockQuantity

        return WooCommerce.ProductListItem(
            siteID: siteID,
            productID: productID,
            name: name,
            productTypeKey: productTypeKey,
            statusKey: statusKey,
            sku: sku,
            manageStock: manageStock,
            stockQuantity: stockQuantity,
            stockStatusKey: stockStatusKey,
            imageURL: imageURL,
            variations: variations,
            bundleStockStatus: bundleStockStatus,
            bundleStockQuantity: bundleStockQuantity
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

// swiftlint:enable line_length
