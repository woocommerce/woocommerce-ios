// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Networking

extension Product {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Product {
        .init(
            siteID: .fake(),
            productID: .fake(),
            name: .fake(),
            slug: .fake(),
            permalink: .fake(),
            date: .fake(),
            dateCreated: .fake(),
            dateModified: .fake(),
            dateOnSaleStart: .fake(),
            dateOnSaleEnd: .fake(),
            productTypeKey: .fake(),
            statusKey: .fake(),
            featured: .fake(),
            catalogVisibilityKey: .fake(),
            fullDescription: .fake(),
            shortDescription: .fake(),
            sku: .fake(),
            price: .fake(),
            regularPrice: .fake(),
            salePrice: .fake(),
            onSale: .fake(),
            purchasable: .fake(),
            totalSales: .fake(),
            virtual: .fake(),
            downloadable: .fake(),
            downloads: .fake(),
            downloadLimit: .fake(),
            downloadExpiry: .fake(),
            buttonText: .fake(),
            externalURL: .fake(),
            taxStatusKey: .fake(),
            taxClass: .fake(),
            manageStock: .fake(),
            stockQuantity: .fake(),
            stockStatusKey: .fake(),
            backordersKey: .fake(),
            backordersAllowed: .fake(),
            backordered: .fake(),
            soldIndividually: .fake(),
            weight: .fake(),
            dimensions: .fake(),
            shippingRequired: .fake(),
            shippingTaxable: .fake(),
            shippingClass: .fake(),
            shippingClassID: .fake(),
            productShippingClass: .fake(),
            reviewsAllowed: .fake(),
            averageRating: .fake(),
            ratingCount: .fake(),
            relatedIDs: .fake(),
            upsellIDs: .fake(),
            crossSellIDs: .fake(),
            parentID: .fake(),
            purchaseNote: .fake(),
            categories: .fake(),
            tags: .fake(),
            images: .fake(),
            attributes: .fake(),
            defaultAttributes: .fake(),
            variations: .fake(),
            groupedProducts: .fake(),
            menuOrder: .fake()
        )
    }
}
extension ProductAttribute {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductAttribute {
        .init(
            siteID: .fake(),
            attributeID: .fake(),
            name: .fake(),
            position: .fake(),
            visible: .fake(),
            variation: .fake(),
            options: .fake()
        )
    }
}
extension ProductBackordersSetting {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductBackordersSetting {
        .allowed
    }
}
extension ProductCatalogVisibility {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductCatalogVisibility {
        .visible
    }
}
extension ProductCategory {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductCategory {
        .init(
            categoryID: .fake(),
            siteID: .fake(),
            parentID: .fake(),
            name: .fake(),
            slug: .fake()
        )
    }
}
extension ProductDefaultAttribute {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductDefaultAttribute {
        .init(
            attributeID: .fake(),
            name: .fake(),
            option: .fake()
        )
    }
}
extension ProductDimensions {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductDimensions {
        .init(
            length: .fake(),
            width: .fake(),
            height: .fake()
        )
    }
}
extension ProductDownload {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductDownload {
        .init(
            downloadID: .fake(),
            name: .fake(),
            fileURL: .fake()
        )
    }
}
extension ProductImage {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductImage {
        .init(
            imageID: .fake(),
            dateCreated: .fake(),
            dateModified: .fake(),
            src: .fake(),
            name: .fake(),
            alt: .fake()
        )
    }
}
extension ProductShippingClass {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductShippingClass {
        .init(
            count: .fake(),
            descriptionHTML: .fake(),
            name: .fake(),
            shippingClassID: .fake(),
            siteID: .fake(),
            slug: .fake()
        )
    }
}
extension ProductStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductStatus {
        .publish
    }
}
extension ProductStockStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductStockStatus {
        .inStock
    }
}
extension ProductTag {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductTag {
        .init(
            siteID: .fake(),
            tagID: .fake(),
            name: .fake(),
            slug: .fake()
        )
    }
}
extension ProductTaxStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductTaxStatus {
        .taxable
    }
}
extension ProductType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductType {
        .simple
    }
}
