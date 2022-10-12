import Foundation
import CoreData


extension CustomerSearchResult {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomerSearchResult> {
        return NSFetchRequest<CustomerSearchResult>(entityName: "CustomerSearchResult")
    }

    @NSManaged public var customerID: Int64
    @NSManaged public var id: NSSet?

}

// MARK: Generated accessors for id
extension CustomerSearchResult {

    @objc(addIdObject:)
    @NSManaged public func addToId(_ value: Customer)

    @objc(removeIdObject:)
    @NSManaged public func removeFromId(_ value: Customer)

    @objc(addId:)
    @NSManaged public func addToId(_ values: NSSet)

    @objc(removeId:)
    @NSManaged public func removeFromId(_ values: NSSet)

}

extension CustomerSearchResult: Identifiable {

}
