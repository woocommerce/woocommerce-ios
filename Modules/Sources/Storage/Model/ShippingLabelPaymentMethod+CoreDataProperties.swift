import Foundation
import CoreData


extension ShippingLabelPaymentMethod {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShippingLabelPaymentMethod> {
        return NSFetchRequest<ShippingLabelPaymentMethod>(entityName: "ShippingLabelPaymentMethod")
    }

    @NSManaged public var cardDigits: String?
    @NSManaged public var cardType: String?
    @NSManaged public var expiry: Date?
    @NSManaged public var name: String?
    @NSManaged public var paymentMethodID: Int64
    @NSManaged public var accountSettings: ShippingLabelAccountSettings?

}
