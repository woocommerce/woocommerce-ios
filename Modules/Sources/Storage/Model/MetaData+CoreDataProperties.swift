import Foundation
import CoreData


extension MetaData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MetaData> {
        return NSFetchRequest<MetaData>(entityName: "MetaData")
    }

    @NSManaged public var key: String?
    @NSManaged public var value: String?
    @NSManaged public var metadataID: Int64
    @NSManaged public var order: Order?
    @NSManaged public var product: Product?

}

extension MetaData: Identifiable {

}
