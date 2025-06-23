import Foundation
import CoreData


extension WooShippingSavedPredefinedPackage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WooShippingSavedPredefinedPackage> {
        return NSFetchRequest<WooShippingSavedPredefinedPackage>(entityName: "WooShippingSavedPredefinedPackage")
    }

    @NSManaged public var groupTitle: String?
    @NSManaged public var providerID: String?
    @NSManaged public var package: WooShippingPredefinedPackage?
    @NSManaged public var packagesResponse: WooShippingPackagesResponse?

}

extension WooShippingSavedPredefinedPackage: Identifiable {

}
