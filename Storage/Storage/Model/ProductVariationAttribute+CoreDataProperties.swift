import Foundation
import CoreData


extension ProductVariationAttribute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductVariationAttribute> {
        return NSFetchRequest<ProductVariationAttribute>(entityName: "ProductVariationAttribute")
    }

    @NSManaged public var attributeID: Int64
    @NSManaged public var name: String?
    @NSManaged public var option: String?
    @NSManaged public var productVariation: ProductVariation?

}
