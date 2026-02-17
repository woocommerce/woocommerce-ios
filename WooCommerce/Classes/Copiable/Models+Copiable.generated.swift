// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import Foundation
import Yosemite

// swiftlint:disable line_length

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

// swiftlint:enable line_length
