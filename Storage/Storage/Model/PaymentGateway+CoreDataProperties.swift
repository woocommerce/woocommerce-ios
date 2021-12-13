import Foundation
import CoreData

extension PaymentGateway {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PaymentGateway> {
        return NSFetchRequest<PaymentGateway>(entityName: "PaymentGateway")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var gatewayID: String
    @NSManaged public var title: String
    @NSManaged public var gatewayDescription: String
    @NSManaged public var features: [String]
    @NSManaged public var enabled: Bool

}
