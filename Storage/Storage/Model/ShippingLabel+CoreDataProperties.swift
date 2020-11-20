import Foundation
import CoreData


extension ShippingLabel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShippingLabel> {
        return NSFetchRequest<ShippingLabel>(entityName: "ShippingLabel")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var orderID: Int64
    @NSManaged public var shippingLabelID: Int64
    @NSManaged public var carrierID: String
    @NSManaged public var dateCreated: Date
    @NSManaged public var packageName: String
    @NSManaged public var rate: Double
    @NSManaged public var currency: String
    @NSManaged public var trackingNumber: String
    @NSManaged public var serviceName: String
    @NSManaged public var refundableAmount: Double
    @NSManaged public var status: String
    @NSManaged public var productIDs: [Int64]
    @NSManaged public var productNames: [String]
    @NSManaged public var originAddress: ShippingLabelAddress?
    @NSManaged public var destinationAddress: ShippingLabelAddress?
    @NSManaged public var refund: ShippingLabelRefund?
    @NSManaged public var order: Order?

}
