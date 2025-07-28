import Foundation
import CoreData


extension ProductDimensions {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductDimensions> {
        return NSFetchRequest<ProductDimensions>(entityName: "ProductDimensions")
    }

    @NSManaged public var length: String
    @NSManaged public var width: String
    @NSManaged public var height: String
    @NSManaged public var product: Product?
    @NSManaged public var productVariation: ProductVariation?

}
