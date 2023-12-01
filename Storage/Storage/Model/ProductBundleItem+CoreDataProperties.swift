import Foundation
import CoreData


extension ProductBundleItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductBundleItem> {
        return NSFetchRequest<ProductBundleItem>(entityName: "ProductBundleItem")
    }

    @NSManaged public var bundledItemID: Int64
    @NSManaged public var menuOrder: Int64
    @NSManaged public var productID: Int64
    @NSManaged public var stockStatus: String?
    @NSManaged public var title: String?
    @NSManaged public var minQuantity: NSDecimalNumber
    @NSManaged public var maxQuantity: NSDecimalNumber?
    @NSManaged public var defaultQuantity: NSDecimalNumber
    @NSManaged public var isOptional: Bool
    @NSManaged public var overridesVariations: Bool
    @NSManaged public var overridesDefaultVariationAttributes: Bool
    @NSManaged public var allowedVariations: [Int64]?
    @NSManaged public var product: Product?
    @NSManaged public var defaultVariationAttributes: NSOrderedSet?
    @NSManaged public var pricedIndividually: Bool
}

// MARK: Generated accessors for defaultVariationAttributes
extension ProductBundleItem {

    @objc(insertObject:inDefaultVariationAttributesAtIndex:)
    @NSManaged public func insertIntoDefaultVariationAttributes(_ value: GenericAttribute, at idx: Int)

    @objc(removeObjectFromDefaultVariationAttributesAtIndex:)
    @NSManaged public func removeFromDefaultVariationAttributes(at idx: Int)

    @objc(insertDefaultVariationAttributes:atIndexes:)
    @NSManaged public func insertIntoDefaultVariationAttributes(_ values: [GenericAttribute], at indexes: NSIndexSet)

    @objc(removeDefaultVariationAttributesAtIndexes:)
    @NSManaged public func removeFromDefaultVariationAttributes(at indexes: NSIndexSet)

    @objc(replaceObjectInDefaultVariationAttributesAtIndex:withObject:)
    @NSManaged public func replaceDefaultVariationAttributes(at idx: Int, with value: GenericAttribute)

    @objc(replaceDefaultVariationAttributesAtIndexes:withDefaultVariationAttributes:)
    @NSManaged public func replaceDefaultVariationAttributes(at indexes: NSIndexSet, with values: [GenericAttribute])

    @objc(addDefaultVariationAttributesObject:)
    @NSManaged public func addToDefaultVariationAttributes(_ value: GenericAttribute)

    @objc(removeDefaultVariationAttributesObject:)
    @NSManaged public func removeFromDefaultVariationAttributes(_ value: GenericAttribute)

    @objc(addDefaultVariationAttributes:)
    @NSManaged public func addToDefaultVariationAttributes(_ values: NSOrderedSet)

    @objc(removeDefaultVariationAttributes:)
    @NSManaged public func removeFromDefaultVariationAttributes(_ values: NSOrderedSet)

}

extension ProductBundleItem: Identifiable {

}
