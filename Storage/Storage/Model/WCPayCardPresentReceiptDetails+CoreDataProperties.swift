import Foundation
import CoreData


extension WCPayCardPresentReceiptDetails {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WCPayCardPresentReceiptDetails> {
        return NSFetchRequest<WCPayCardPresentReceiptDetails>(entityName: "WCPayCardPresentReceiptDetails")
    }

    @NSManaged public var accountType: String?
    @NSManaged public var applicationPreferredName: String?
    @NSManaged public var dedicatedFileName: String?
    @NSManaged public var cardPresentPayment: WCPayCardPresentPaymentDetails?

}

extension WCPayCardPresentReceiptDetails: Identifiable {

}
