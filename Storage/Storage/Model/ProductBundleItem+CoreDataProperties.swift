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
    @NSManaged public var minQuantity: Int64
    @NSManaged public var maxQuantity: NSNumber?
    @NSManaged public var defaultQuantity: Int64
    @NSManaged public var isOptional: Bool
    @NSManaged public var isPricedIndividually: Bool
    @NSManaged public var discount: NSNumber?
    @NSManaged public var product: Product?

}

extension ProductBundleItem: Identifiable {

}
