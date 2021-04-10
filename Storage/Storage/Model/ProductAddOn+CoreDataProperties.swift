import Foundation
import CoreData

extension ProductAddOn {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductAddOn> {
        return NSFetchRequest<ProductAddOn>(entityName: "ProductAddOn")
    }

    @NSManaged public var type: String
    @NSManaged public var display: String
    @NSManaged public var name: String
    @NSManaged public var titleFormat: String
    @NSManaged public var descriptionEnabled: Int
    @NSManaged public var descriptions: String
    @NSManaged public var required: Int
    @NSManaged public var position: Int
    @NSManaged public var restrictions: Int
    @NSManaged public var restrictionsType: String
    @NSManaged public var adjustPrice: Int
    @NSManaged public var priceType: String
    @NSManaged public var price: String
    @NSManaged public var min: Int
    @NSManaged public var max: Int
    @NSManaged public var options: NSOrderedSet?
    @NSManaged public var product: Product?

}

// MARK: Generated accessors for options
extension ProductAddOn {

    @objc(addOptionsObject:)
    @NSManaged public func addToOptions(_ value: ProductAddOnOption)

    @objc(removeOptionsObject:)
    @NSManaged public func removeFromOptions(_ value: ProductAddOnOption)

    @objc(addOptions:)
    @NSManaged public func addToOptions(_ values: NSOrderedSet)

    @objc(removeOptions:)
    @NSManaged public func removeFromOptions(_ values: NSOrderedSet)

}
