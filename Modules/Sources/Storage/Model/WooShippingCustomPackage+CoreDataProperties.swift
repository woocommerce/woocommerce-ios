import Foundation
import CoreData


extension WooShippingCustomPackage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WooShippingCustomPackage> {
        return NSFetchRequest<WooShippingCustomPackage>(entityName: "WooShippingCustomPackage")
    }

    @NSManaged public var boxWeight: Double
    @NSManaged public var dimensions: String?
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var rawType: String?
    @NSManaged public var packagesResponse: WooShippingPackagesResponse?
}

extension WooShippingCustomPackage: Identifiable {
}
