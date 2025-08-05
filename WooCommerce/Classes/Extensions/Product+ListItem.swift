import Foundation
import Yosemite

extension Product {
    func toListItem() -> ProductListItem {
        ProductListItem(siteID: siteID,
                        productID: productID,
                        name: name,
                        permalink: permalink,
                        fullDescription: fullDescription,
                        shortDescription: shortDescription,
                        productTypeKey: productTypeKey,
                        statusKey: statusKey,
                        sku: sku,
                        price: price,
                        manageStock: manageStock,
                        stockQuantity: stockQuantity,
                        stockStatusKey: stockStatusKey,
                        imageURL: imageURL,
                        variations: variations,
                        bundleStockStatus: bundleStockStatus,
                        bundleStockQuantity: bundleStockQuantity)
    }
}
