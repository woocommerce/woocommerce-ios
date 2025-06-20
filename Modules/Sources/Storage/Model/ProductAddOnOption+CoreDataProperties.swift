import Foundation
import CoreData

extension ProductAddOnOption {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductAddOnOption> {
        return NSFetchRequest<ProductAddOnOption>(entityName: "ProductAddOnOption")
    }

    @NSManaged public var label: String?
    @NSManaged public var price: String?
    @NSManaged public var imageID: String?
    @NSManaged public var priceType: String?
    @NSManaged public var addOn: ProductAddOn?

}
