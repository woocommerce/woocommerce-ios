import Foundation
import Yosemite

extension Product {
    func toListItem() -> ProductListItem {
        ProductListItem(siteID: siteID,
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
                        bundleStockQuantity: bundleStockQuantity)
    }
}
