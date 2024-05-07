import Storage // See notes on POSProductAdapter. Storage import, if needed, only limited to the adapter.

// The adapter should be located in WCiOS, and POSProduct would be a shared structure, since we do not want to import Yosemite or Storage into the POS
// This adapter class could act as a mere namespace for the adapter/mapper methods if we only use static functions.
final class POSProductAdapter {
    // Maps from Woo Product to POS Product
    // Right now the input comes from Storage.Product, but later can come from anywhere else, we do not care where data originates from.
    static func makePOSProduct(input product: Storage.Product) -> POSProduct {
        return POSProduct(siteID: product.siteID,
                          productID: product.productID,
                          name: product.name,
                          price: product.price)
    }

    // Maps from Woo Products to POS Products
    static func makePOSProductList(input products: [Storage.Product]) -> [POSProduct] {
        return products.map { input in
            POSProduct(siteID: input.siteID,
                       productID: input.productID,
                       name: input.name,
                       price: input.price)
        }
    }

    // Maps from Woo Products to POS Products
    static func makePOSProductList() -> [POSProduct] {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID,
              let wooProducts = ServiceLocator.storageManager.viewStorage.loadProducts(siteID: siteID) else {
            assertionFailure("There should be products loaded from storage at this point.")
            return []
        }

        let posProducts = makePOSProductList(input: wooProducts)
        return posProducts
    }
}
