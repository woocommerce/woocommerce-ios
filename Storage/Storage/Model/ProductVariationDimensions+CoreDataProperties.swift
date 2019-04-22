import Foundation
import CoreData


extension ProductVariationDimensions {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductVariationDimensions> {
        return NSFetchRequest<ProductVariationDimensions>(entityName: "ProductVariationDimensions")
    }

    @NSManaged public var height: String
    @NSManaged public var width: String
    @NSManaged public var length: String
    @NSManaged public var productVariation: ProductVariation?

}
