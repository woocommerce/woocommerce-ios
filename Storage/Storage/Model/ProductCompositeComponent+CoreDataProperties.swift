import Foundation
import CoreData


extension ProductCompositeComponent {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductCompositeComponent> {
        return NSFetchRequest<ProductCompositeComponent>(entityName: "ProductCompositeComponent")
    }

    @NSManaged public var componentID: String?
    @NSManaged public var title: String?
    @NSManaged public var optionType: String?
    @NSManaged public var imageURL: String?
    @NSManaged public var optionIDs: [Int64]?
    @NSManaged public var componentDescription: String?
    @NSManaged public var defaultOptionID: String?
    @NSManaged public var product: Product?

}

extension ProductCompositeComponent: Identifiable {

}
