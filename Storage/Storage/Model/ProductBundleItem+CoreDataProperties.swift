import Foundation
import CoreData


extension ProductBundleItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductBundleItem> {
        return NSFetchRequest<ProductBundleItem>(entityName: "ProductBundleItem")
    }

    @NSManaged public var bundledItemID: Int64
    @NSManaged public var menuOrder: Int64
    @NSManaged public var productID: Int64
    @NSManaged public var stockStatus: String?
    @NSManaged public var title: String?
    @NSManaged public var minQuantity: NSDecimalNumber
    @NSManaged public var maxQuantity: NSDecimalNumber?
    @NSManaged public var defaultQuantity: NSDecimalNumber
    @NSManaged public var isOptional: Bool
    @NSManaged public var product: Product?

}

extension ProductBundleItem: Identifiable {

}
