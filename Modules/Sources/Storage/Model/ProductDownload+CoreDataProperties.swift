import Foundation
import CoreData


extension ProductDownload {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductDownload> {
        return NSFetchRequest<ProductDownload>(entityName: "ProductDownload")
    }

    @NSManaged public var downloadID: String
    @NSManaged public var name: String?
    @NSManaged public var fileURL: String?
    @NSManaged public var product: Product?
    @NSManaged public var productVariation: ProductVariation?

}
