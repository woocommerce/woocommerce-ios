import WooCommerce
import Yosemite

extension Product {
    func toOrderDetailsProduct() -> OrderDetailsProduct {
        OrderDetailsProduct(siteID: siteID,
                            productID: productID,
                            name: name,
                            productTypeKey: productTypeKey,
                            sku: sku,
                            price: price,
                            virtual: virtual,
                            stockQuantity: stockQuantity,
                            imageURL: imageURL,
                            addOns: addOns)
    }
}
