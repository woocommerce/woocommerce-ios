import Foundation
import CoreData


extension ProductVariationImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductVariationImage> {
        return NSFetchRequest<ProductVariationImage>(entityName: "ProductVariationImage")
    }

    @NSManaged public var alt: String?
    @NSManaged public var dateCreated: Date
    @NSManaged public var dateModified: Date?
    @NSManaged public var imageID: Int64
    @NSManaged public var name: String?
    @NSManaged public var src: String
    @NSManaged public var productVariation: Product?

}
