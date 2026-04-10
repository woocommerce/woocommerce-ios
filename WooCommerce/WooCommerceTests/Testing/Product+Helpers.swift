import Foundation
@testable import WooCommerce
import Yosemite

extension Product {
    func toOrderDetailsProduct() -> OrderDetailsProduct {
        OrderDetailsProduct(productID: productID,
                            productTypeKey: productTypeKey,
                            sku: sku,
                            price: price,
                            virtual: virtual,
                            imageURL: imageURL,
                            addOns: addOns)
    }
}
