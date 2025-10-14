import Foundation
import CoreData


public typealias BookingProductInfoCoreDataPropertiesSet = NSSet

extension BookingProductInfo {
    @NSManaged public var name: String?
    @NSManaged public var orderInfo: BookingOrderInfo?

}
