import Foundation
import CoreData


extension Product {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Product> {
        return NSFetchRequest<Product>(entityName: "Product")
    }


    @NSManaged public var siteID: Int64
    @NSManaged public var productID: Int64
    @NSManaged public var productTypeKey: String
    @NSManaged public var name: String
    @NSManaged public var slug: String
    @NSManaged public var permalink: String
    @NSManaged public var dateCreated: Date
    @NSManaged public var dateModified: Date?
    @NSManaged public var dateOnSaleStart: Date?
    @NSManaged public var dateOnSaleEnd: Date?
    @NSManaged public var statusKey: String
    @NSManaged public var featured: Bool
    @NSManaged public var catalogVisibilityKey: String
    @NSManaged public var fullDescription: String?
    @NSManaged public var briefDescription: String?
    @NSManaged public var sku: String?
    @NSManaged public var price: String
    @NSManaged public var regularPrice: String?
    @NSManaged public var salePrice: String?
    @NSManaged public var onSale: Bool
    @NSManaged public var purchasable: Bool
    @NSManaged public var totalSales: Int64
    @NSManaged public var virtual: Bool
    @NSManaged public var downloadable: Bool
    @NSManaged public var downloadLimit: Int64
    @NSManaged public var downloadExpiry: Int64
    @NSManaged public var externalURL: String?
    @NSManaged public var taxStatusKey: String
    @NSManaged public var taxClass: String?
    @NSManaged public var manageStock: Bool
    @NSManaged public var stockQuantity: String?
    @NSManaged public var stockStatusKey: String
    @NSManaged public var soldIndividually: Bool
    @NSManaged public var weight: String?
    @NSManaged public var shippingRequired: Bool
    @NSManaged public var shippingTaxable: Bool
    @NSManaged public var shippingClass: String?
    @NSManaged public var shippingClassID: Int64
    @NSManaged public var reviewsAllowed: Bool
    @NSManaged public var averageRating: String
    @NSManaged public var ratingCount: Int64
    @NSManaged public var relatedIDs: [Int64]?
    @NSManaged public var upsellIDs: [Int64]?
    @NSManaged public var crossSellIDs: [Int64]?
    @NSManaged public var parentID: Int64
    @NSManaged public var purchaseNote: String?
    @NSManaged public var variations: [Int64]?
    @NSManaged public var groupedProducts: [Int64]?
    @NSManaged public var menuOrder: Int64
    @NSManaged public var backordersKey: String
    @NSManaged public var backordersAllowed: Bool
    @NSManaged public var backordered: Bool
    @NSManaged public var buttonText: String
    @NSManaged public var dimensions: ProductDimensions?
    @NSManaged public var attributes: Set<ProductAttribute>?
    @NSManaged public var categories: Set<ProductCategory>?
    @NSManaged public var defaultAttributes: Set<ProductDefaultAttribute>?
    @NSManaged public var downloads: Set<ProductDownload>?
    @NSManaged public var images: NSOrderedSet?
    @NSManaged public var tags: Set<ProductTag>?
    @NSManaged public var searchResults: Set<ProductSearchResults>?
    @NSManaged public var productVariations: Set<ProductVariation>?
    @NSManaged public var productShippingClass: ProductShippingClass?

}

// MARK: Generated accessors for attributes
extension Product {

    @objc(addAttributesObject:)
    @NSManaged public func addToAttributes(_ value: ProductAttribute)

    @objc(removeAttributesObject:)
    @NSManaged public func removeFromAttributes(_ value: ProductAttribute)

    @objc(addAttributes:)
    @NSManaged public func addToAttributes(_ values: NSSet)

    @objc(removeAttributes:)
    @NSManaged public func removeFromAttributes(_ values: NSSet)

}

// MARK: Generated accessors for categories
extension Product {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: ProductCategory)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: ProductCategory)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)

}

// MARK: Generated accessors for defaultAttributes
extension Product {

    @objc(addDefaultAttributesObject:)
    @NSManaged public func addToDefaultAttributes(_ value: ProductDefaultAttribute)

    @objc(removeDefaultAttributesObject:)
    @NSManaged public func removeFromDefaultAttributes(_ value: ProductDefaultAttribute)

    @objc(addDefaultAttributes:)
    @NSManaged public func addToDefaultAttributes(_ values: NSSet)

    @objc(removeDefaultAttributes:)
    @NSManaged public func removeFromDefaultAttributes(_ values: NSSet)

}

// MARK: Generated accessors for downloads
extension Product {

    @objc(addDownloadsObject:)
    @NSManaged public func addToDownloads(_ value: ProductDownload)

    @objc(removeDownloadsObject:)
    @NSManaged public func removeFromDownloads(_ value: ProductDownload)

    @objc(addDownloads:)
    @NSManaged public func addToDownloads(_ values: NSSet)

    @objc(removeDownloads:)
    @NSManaged public func removeFromDownloads(_ values: NSSet)

}

// MARK: Generated accessors for images
extension Product {

    @objc(insertObject:inImagesAtIndex:)
    @NSManaged public func insertIntoImages(_ value: ProductImage, at idx: Int)

    @objc(removeObjectFromImagesAtIndex:)
    @NSManaged public func removeFromImages(at idx: Int)

    @objc(insertImages:atIndexes:)
    @NSManaged public func insertIntoImages(_ values: [ProductImage], at indexes: NSIndexSet)

    @objc(removeImagesAtIndexes:)
    @NSManaged public func removeFromImages(at indexes: NSIndexSet)

    @objc(replaceObjectInImagesAtIndex:withObject:)
    @NSManaged public func replaceImages(at idx: Int, with value: ProductImage)

    @objc(replaceImagesAtIndexes:withImages:)
    @NSManaged public func replaceImages(at indexes: NSIndexSet, with values: [ProductImage])

    @objc(addImagesObject:)
    @NSManaged public func addToImages(_ value: ProductImage)

    @objc(removeImagesObject:)
    @NSManaged public func removeFromImages(_ value: ProductImage)

    @objc(addImages:)
    @NSManaged public func addToImages(_ values: NSOrderedSet)

    @objc(removeImages:)
    @NSManaged public func removeFromImages(_ values: NSOrderedSet)

}

// MARK: Generated accessors for tags
extension Product {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: ProductTag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: ProductTag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

}

// MARK: Generated accessors for searchResults
extension Product {

    @objc(addSearchResultsObject:)
    @NSManaged public func addToSearchResults(_ value: ProductSearchResults)

    @objc(removeSearchResultsObject:)
    @NSManaged public func removeFromSearchResults(_ value: ProductSearchResults)

    @objc(addSearchResults:)
    @NSManaged public func addToSearchResults(_ values: NSSet)

    @objc(removeSearchResults:)
    @NSManaged public func removeFromSearchResults(_ values: NSSet)

}

// MARK: Generated accessors for productVariations
extension Product {

    @objc(addProductVariationsObject:)
    @NSManaged public func addToProductVariations(_ value: ProductVariation)

    @objc(removeProductVariationsObject:)
    @NSManaged public func removeFromProductVariations(_ value: ProductVariation)

    @objc(addProductVariations:)
    @NSManaged public func addToProductVariations(_ values: NSSet)

    @objc(removeProductVariations:)
    @NSManaged public func removeFromProductVariations(_ values: NSSet)

}
