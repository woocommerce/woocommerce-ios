import Foundation
import CoreData


extension WCPayCharge {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WCPayCharge> {
        return NSFetchRequest<WCPayCharge>(entityName: "WCPayCharge")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var id: String?
    @NSManaged public var amount: Int64
    @NSManaged public var amountCaptured: Int64
    @NSManaged public var amountRefunded: Int64
    @NSManaged public var authorizationCode: String?
    @NSManaged public var captured: Bool
    @NSManaged public var created: Date?
    @NSManaged public var currency: String?
    @NSManaged public var paid: Bool
    @NSManaged public var paymentIntentID: String?
    @NSManaged public var paymentMethodID: String?
    @NSManaged public var refunded: Bool
    @NSManaged public var status: String?
    @NSManaged public var paymentMethodType: String?
    @NSManaged public var cardDetails: WCPayCardPaymentDetails?
    @NSManaged public var cardPresentDetails: WCPayCardPresentPaymentDetails?

}

extension WCPayCharge: Identifiable {

}
