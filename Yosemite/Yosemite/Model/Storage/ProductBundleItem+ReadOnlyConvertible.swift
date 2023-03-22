import Foundation
import Networking
import Storage

// MARK: - Storage.ProductBundleItem: ReadOnlyConvertible
//
extension Storage.ProductBundleItem: ReadOnlyConvertible {

    /// Updates the Storage.ProductBundleItem with the ReadOnly.
    ///
    public func update(with bundleItem: Yosemite.ProductBundleItem) {
        bundledItemID = bundleItem.bundledItemID
        productID = bundleItem.productID
        menuOrder = bundleItem.menuOrder
        title = bundleItem.title
        stockStatus = bundleItem.stockStatus.rawValue
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductBundleItem {
        return ProductBundleItem(bundledItemID: bundledItemID,
                                 productID: productID,
                                 menuOrder: menuOrder,
                                 title: title ?? "",
                                 stockStatus: ProductBundleItemStockStatus(rawValue: stockStatus ?? "in_stock") ?? .inStock)
    }
}
