import Foundation
import CoreData


extension ProductSubscription {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductSubscription> {
        return NSFetchRequest<ProductSubscription>(entityName: "ProductSubscription")
    }

    @NSManaged public var length: String?
    @NSManaged public var period: String?
    @NSManaged public var periodInterval: String?
    @NSManaged public var price: String?
    @NSManaged public var signUpFee: String?
    @NSManaged public var trialLength: String?
    @NSManaged public var trialPeriod: String?
    @NSManaged public var product: Product?
    @NSManaged public var productVariation: ProductVariation?

}

extension ProductSubscription: Identifiable {

}
