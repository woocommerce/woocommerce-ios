import Foundation
import CoreData


extension ProductVariation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductVariation> {
        return NSFetchRequest<ProductVariation>(entityName: "ProductVariation")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var variationID: Int64
    @NSManaged public var productID: Int64

    @NSManaged public var backordered: Bool
    @NSManaged public var backordersAllowed: Bool
    @NSManaged public var backordersKey: String
    @NSManaged public var dateCreated: Date
    @NSManaged public var dateModified: Date?
    @NSManaged public var dateOnSaleFrom: Date?
    @NSManaged public var dateOnSaleTo: Date?
    @NSManaged public var downloadable: Bool
    @NSManaged public var downloadExpiry: Int64
    @NSManaged public var downloadLimit: Int64
    @NSManaged public var fullDescription: String?
    @NSManaged public var manageStock: Bool
    @NSManaged public var menuOrder: Int64
    @NSManaged public var onSale: Bool
    @NSManaged public var permalink: String?
    @NSManaged public var price: String
    @NSManaged public var purchasable: Bool
    @NSManaged public var regularPrice: String?
    @NSManaged public var salePrice: String?
    @NSManaged public var shippingClass: String
    @NSManaged public var shippingClassID: String
    @NSManaged public var sku: String?
    @NSManaged public var statusKey: String?
    @NSManaged public var stockQuantity: Int64
    @NSManaged public var stockStatusKey: String?
    @NSManaged public var taxClass: String?
    @NSManaged public var taxStatusKey: String?
    @NSManaged public var virtual: Bool
    @NSManaged public var weight: String?

    @NSManaged public var dimensions: ProductVariationDimensions?
    @NSManaged public var image: ProductVariationImage?
    @NSManaged public var attributes: Set<ProductVariationAttribute>?
}

// MARK: Generated accessors for attributes
extension ProductVariation {

    @objc(addAttributesObject:)
    @NSManaged public func addToAttributes(_ value: ProductVariationAttribute)

    @objc(removeAttributesObject:)
    @NSManaged public func removeFromAttributes(_ value: ProductVariationAttribute)

    @objc(addAttributes:)
    @NSManaged public func addToAttributes(_ values: NSSet)

    @objc(removeAttributes:)
    @NSManaged public func removeFromAttributes(_ values: NSSet)

}
