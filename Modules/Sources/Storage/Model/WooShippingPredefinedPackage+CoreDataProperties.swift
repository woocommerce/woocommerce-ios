import Foundation
import CoreData


extension WooShippingPredefinedPackage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WooShippingPredefinedPackage> {
        return NSFetchRequest<WooShippingPredefinedPackage>(entityName: "WooShippingPredefinedPackage")
    }

    @NSManaged public var boxWeight: String?
    @NSManaged public var dimensions: String?
    @NSManaged public var groupID: String?
    @NSManaged public var id: String?
    @NSManaged public var isLetter: Bool
    @NSManaged public var name: String?
    @NSManaged public var predefinedOption: WooShippingPredefinedOption?
    @NSManaged public var savedPredefinedPackage: WooShippingSavedPredefinedPackage?
}

extension WooShippingPredefinedPackage: Identifiable {
}
