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
                        price: price,
                        virtual: virtual,
                        manageStock: manageStock,
                        stockQuantity: stockQuantity,
                        stockStatusKey: stockStatusKey,
                        reviewsAllowed: reviewsAllowed,
                        averageRating: averageRating,
                        ratingCount: ratingCount,
                        images: images,
                        addOns: addOns,
                        variations: variations,
                        bundleStockStatus: bundleStockStatus,
                        bundleStockQuantity: bundleStockQuantity)
    }
}
