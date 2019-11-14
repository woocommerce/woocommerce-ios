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
    @NSManaged public var stockQuantity: String?
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
    @NSManaged public var attributes: [Attribute]?
    @NSManaged public var dimensions: ProductDimensions?
    @NSManaged public var image: ProductImage?
    @NSManaged public var downloads: NSSet?
    @NSManaged public var product: Product?

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
