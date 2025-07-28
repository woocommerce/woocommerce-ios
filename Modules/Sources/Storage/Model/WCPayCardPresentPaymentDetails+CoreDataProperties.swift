import Foundation
import CoreData


extension WCPayCardPresentPaymentDetails {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WCPayCardPresentPaymentDetails> {
        return NSFetchRequest<WCPayCardPresentPaymentDetails>(entityName: "WCPayCardPresentPaymentDetails")
    }

    @NSManaged public var brand: String
    @NSManaged public var last4: String
    @NSManaged public var funding: String
    @NSManaged public var receipt: WCPayCardPresentReceiptDetails?
    @NSManaged public var charge: WCPayCharge?

}

extension WCPayCardPresentPaymentDetails: Identifiable {

}
