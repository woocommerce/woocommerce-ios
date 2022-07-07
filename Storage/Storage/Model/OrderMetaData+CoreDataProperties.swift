import Foundation
import CoreData


extension OrderMetaData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderMetaData> {
        return NSFetchRequest<OrderMetaData>(entityName: "OrderMetaData")
    }

    @NSManaged public var key: String?
    @NSManaged public var value: String?
    @NSManaged public var metadataID: Int64
    @NSManaged public var order: Order?

}

extension OrderMetaData: Identifiable {

}
