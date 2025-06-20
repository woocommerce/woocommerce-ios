import Foundation
import CoreData

extension AddOnGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AddOnGroup> {
        return NSFetchRequest<AddOnGroup>(entityName: "AddOnGroup")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var groupID: Int64
    @NSManaged public var name: String?
    @NSManaged public var priority: Int64
    @NSManaged public var addOns: NSOrderedSet?
}

// MARK: Generated accessors for addOns
extension AddOnGroup {
    @objc(addAddOnsObject:)
    @NSManaged public func addToAddOns(_ value: ProductAddOn)

    @objc(removeAddOnsObject:)
    @NSManaged public func removeFromAddOns(_ value: ProductAddOn)

    @objc(addAddOns:)
    @NSManaged public func addToAddOns(_ values: NSOrderedSet)

    @objc(removeAddOns:)
    @NSManaged public func removeFromAddOns(_ values: NSOrderedSet)
}
