import Foundation
import CoreData


extension ProductImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductImage> {
        return NSFetchRequest<ProductImage>(entityName: "ProductImage")
    }

    @NSManaged public var imageID: Int64
    @NSManaged public var dateCreated: Date
    @NSManaged public var dateModified: Date?
    @NSManaged public var src: String
    @NSManaged public var name: String?
    @NSManaged public var alt: String?
    @NSManaged public var product: Product?

}
