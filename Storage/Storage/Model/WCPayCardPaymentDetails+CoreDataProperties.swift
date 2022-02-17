import Foundation
import CoreData


extension WCPayCardPaymentDetails {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WCPayCardPaymentDetails> {
        return NSFetchRequest<WCPayCardPaymentDetails>(entityName: "WCPayCardPaymentDetails")
    }

    @NSManaged public var brand: String
    @NSManaged public var last4: String
    @NSManaged public var funding: String
    @NSManaged public var charge: WCPayCharge?

}

extension WCPayCardPaymentDetails: Identifiable {

}
