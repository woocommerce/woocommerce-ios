import Foundation
import CoreData


extension ProductVariation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductVariation> {
        return NSFetchRequest<ProductVariation>(entityName: "ProductVariation")
    }

    @NSManaged public var dateModified: Date?
    @NSManaged public var dateCreated: Date
    @NSManaged public var fullDescription: String?
    @NSManaged public var permalink: String
    @NSManaged public var productVariationID: Int64
    @NSManaged public var sku: String?
    @NSManaged public var price: String
    @NSManaged public var regularPrice: String?
    @NSManaged public var salePrice: String?
    @NSManaged public var onSale: Bool
    @NSManaged public var statusKey: String
    @NSManaged public var purchasable: Bool
    @NSManaged public var virtual: Bool
    @NSManaged public var downloadable: Bool
    @NSManaged public var downloadLimit: Int64
    @NSManaged public var downloadExpiry: Int64
    @NSManaged public var taxStatusKey: String
    @NSManaged public var taxClass: String?
    @NSManaged public var manageStock: Bool
    @NSManaged public var stockQuantity: Int64
    @NSManaged public var stockStatusKey: String
    @NSManaged public var backordersKey: String
    @NSManaged public var backordersAllowed: Bool
    @NSManaged public var backordered: Bool
    @NSManaged public var weight: String?
    @NSManaged public var shippingClass: String?
    @NSManaged public var shippingClassID: Int64
    @NSManaged public var menuOrder: Int64
    @NSManaged public var dateOnSaleStart: Date?
    @NSManaged public var dateOnSaleEnd: Date?
    @NSManaged public var siteID: Int64
    @NSManaged public var productID: Int64
    @NSManaged public var dimensions: ProductDimensions?
    @NSManaged public var image: ProductImage?
    @NSManaged public var downloads: Set<ProductDownload>?
    @NSManaged public var product: Product?
    @NSManaged public var attributes: NSOrderedSet

}

// MARK: Generated accessors for downloads
extension ProductVariation {

    @objc(addDownloadsObject:)
    @NSManaged public func addToDownloads(_ value: ProductDownload)

    @objc(removeDownloadsObject:)
    @NSManaged public func removeFromDownloads(_ value: ProductDownload)

    @objc(addDownloads:)
    @NSManaged public func addToDownloads(_ values: NSSet)

    @objc(removeDownloads:)
    @NSManaged public func removeFromDownloads(_ values: NSSet)

}

// MARK: Generated accessors for attributes
extension ProductVariation {

    @objc(insertObject:inAttributesAtIndex:)
    @NSManaged public func insertIntoAttributes(_ value: Attribute, at idx: Int)

    @objc(removeObjectFromAttributesAtIndex:)
    @NSManaged public func removeFromAttributes(at idx: Int)

    @objc(insertAttributes:atIndexes:)
    @NSManaged public func insertIntoAttributes(_ values: [Attribute], at indexes: NSIndexSet)

    @objc(removeAttributesAtIndexes:)
    @NSManaged public func removeFromAttributes(at indexes: NSIndexSet)

    @objc(replaceObjectInAttributesAtIndex:withObject:)
    @NSManaged public func replaceAttributes(at idx: Int, with value: Attribute)

    @objc(replaceAttributesAtIndexes:withAttributes:)
    @NSManaged public func replaceAttributes(at indexes: NSIndexSet, with values: [Attribute])

    @objc(addAttributesObject:)
    @NSManaged public func addToAttributes(_ value: Attribute)

    @objc(removeAttributesObject:)
    @NSManaged public func removeFromAttributes(_ value: Attribute)

    @objc(addAttributes:)
    @NSManaged public func addToAttributes(_ values: NSOrderedSet)

    @objc(removeAttributes:)
    @NSManaged public func removeFromAttributes(_ values: NSOrderedSet)

}
