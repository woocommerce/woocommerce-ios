import Foundation


// MARK: - StorageType DataModel Specific Extensions for Deletions
//
public extension StorageType {

    // MARK: - Products

    /// Deletes all of the stored Products for the provided siteID.
    ///
    func deleteProducts(siteID: Int64) {
        guard let products = loadProducts(siteID: siteID) else {
            return
        }
        for product in products {
            deleteObject(product)
        }
    }
}
