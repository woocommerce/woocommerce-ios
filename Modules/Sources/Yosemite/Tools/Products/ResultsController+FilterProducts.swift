import CoreData
import Storage

extension NSPredicate {
    public static func createProductPredicate(siteID: Int64,
                                              stockStatus: ProductStockStatus? = nil,
                                              productStatus: ProductStatus? = nil,
                                              productType: ProductType? = nil,
                                              productIDs: [Int64]? = nil) -> NSPredicate {
        let siteIDPredicate = NSPredicate(format: "siteID == %lld", siteID)

        let stockStatusPredicate = stockStatus.flatMap { stockStatus -> NSPredicate? in
            let key = #selector(getter: StorageProduct.stockStatusKey)
            return NSPredicate(format: "\(key) == %@", stockStatus.rawValue)
        }

        let productStatusPredicate = productStatus.flatMap { productStatus -> NSPredicate? in
            let key = #selector(getter: StorageProduct.statusKey)
            return NSPredicate(format: "\(key) == %@", productStatus.rawValue)
        }

        let productTypePredicate = productType.flatMap { productType -> NSPredicate? in
            let key = #selector(getter: StorageProduct.productTypeKey)
            return NSPredicate(format: "\(key) == %@", productType.rawValue)
        }

        let productIDsPredicate = productIDs.flatMap { productIDs -> NSPredicate? in
            NSPredicate(format: "productID in %@", productIDs)
        }

        let subpredicates = [siteIDPredicate,
                             stockStatusPredicate,
                             productStatusPredicate,
                             productTypePredicate,
                             productIDsPredicate].compactMap({ $0 })


        return NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
    }
}

extension ResultsController where T: StorageProduct {
    public func updatePredicate(siteID: Int64,
                                stockStatus: ProductStockStatus? = nil,
                                productStatus: ProductStatus? = nil,
                                productType: ProductType? = nil,
                                productIDs: [Int64]? = nil) {
        self.predicate = NSPredicate.createProductPredicate(siteID: siteID,
                                                            stockStatus: stockStatus,
                                                            productStatus: productStatus,
                                                            productType: productType,
                                                            productIDs: productIDs)
    }
}
