import Foundation
@testable import Networking


final class MockProduct {

    let testSiteID: Int64 = 2019
    let testProductID: Int64 = 2020

    func product(downloadable: Bool = false,
                 name: String = "Hogsmeade",
                 briefDescription: String? = """
                 [contact-form]\n<p>The green room&#8217;s max capacity is 30 people. Reserving the date / time of your event is free. \
                 We can also accommodate large groups, with seating for 85 board game players at a time. If you have a large group, let us \
                 know and we&#8217;ll send you our large group rate.</p>\n<p>GROUP RATES</p>\n<p>Reserve your event for up to 30 guests \
                 for $100.</p>\n
                 """,
                 fullDescription: String? = "<p>This is the party room!</p>\n",
                 productShippingClass: ProductShippingClass? = nil,
                 backordersSetting: ProductBackordersSetting = .notAllowed,
                 externalURL: String? = "https://example.com",
                 productType: ProductType = .simple,
                 manageStock: Bool = false,
                 sku: String? = "",
                 stockQuantity: Int64? = nil,
                 taxClass: String? = "",
                 taxStatus: ProductTaxStatus = .taxable,
                 stockStatus: ProductStockStatus = .inStock,
                 regularPrice: String? = "",
                 salePrice: String? = "",
                 dateOnSaleStart: Date? = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-15T21:30:00"),
                 dateOnSaleEnd: Date? = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-27T21:29:59"),
                 dimensions: ProductDimensions = ProductDimensions(length: "0", width: "0", height: "0"),
                 weight: String? = "213",
                 variations: [Int64] = [],
                 virtual: Bool = false,
                 status: ProductStatus = .publish,
                 featured: Bool = false,
                 catalogVisibility: ProductCatalogVisibility = .visible,
                 reviewsAllowed: Bool = true,
                 slug: String = "book-the-green-room",
                 menuOrder: Int = 0,
                 categories: [ProductCategory] = [],
                 tags: [ProductTag] = [],
                 images: [ProductImage] = []) -> Product {

    return Product(siteID: testSiteID,
                   productID: testProductID,
                   name: name,
                   slug: slug,
                   permalink: "https://example.com/product/book-the-green-room/",
                   dateCreated: Date(),
                   dateModified: Date(),
                   dateOnSaleStart: dateOnSaleStart,
                   dateOnSaleEnd: dateOnSaleEnd,
                   productTypeKey: productType.rawValue,
                   statusKey: status.rawValue,
                   featured: featured,
                   catalogVisibilityKey: catalogVisibility.rawValue,
                   fullDescription: fullDescription,
                   briefDescription: briefDescription,
                   sku: sku,
                   price: "0",
                   regularPrice: regularPrice,
                   salePrice: salePrice,
                   onSale: false,
                   purchasable: true,
                   totalSales: 0,
                   virtual: virtual,
                   downloadable: downloadable,
                   downloads: downloadable ? sampleDownloads() : [],
                   downloadLimit: downloadable ? 1 : -1,
                   downloadExpiry: downloadable ? 1 : -1,
                   buttonText: "",
                   externalURL: externalURL,
                   taxStatusKey: taxStatus.rawValue,
                   taxClass: taxClass,
                   manageStock: manageStock,
                   stockQuantity: stockQuantity,
                   stockStatusKey: stockStatus.rawValue,
                   backordersKey: backordersSetting.rawValue,
                   backordersAllowed: false,
                   backordered: false,
                   soldIndividually: true,
                   weight: weight,
                   dimensions: dimensions,
                   shippingRequired: false,
                   shippingTaxable: false,
                   shippingClass: "",
                   shippingClassID: 0,
                   productShippingClass: productShippingClass,
                   reviewsAllowed: reviewsAllowed,
                   averageRating: "4.30",
                   ratingCount: 23,
                   relatedIDs: [31, 22, 369, 414, 56],
                   upsellIDs: [99, 1234566],
                   crossSellIDs: [1234, 234234, 3],
                   parentID: 0,
                   purchaseNote: "Thank you!",
                   categories: categories,
                   tags: tags,
                   images: images,
                   attributes: [],
                   defaultAttributes: [],
                   variations: variations,
                   groupedProducts: [],
                   menuOrder: menuOrder)

    }

    func sampleDownloads() -> [Networking.ProductDownload] {
         let download1 = ProductDownload(downloadID: "1f9c11f99ceba63d4403c03bd5391b11",
                                         name: "Song #1",
                                         fileURL: "https://example.com/woo-single-1.ogg")
         let download2 = ProductDownload(downloadID: "ec87d8b5-1361-4562-b4b8-18980b5a2cae",
                                         name: "Artwork",
                                         fileURL: "https://example.com/cd_4_angle.jpg")
         let download3 = ProductDownload(downloadID: "240cd543-5457-498e-95e2-6b51fdaf15cc",
                                         name: "Artwork 2",
                                         fileURL: "https://example.com/cd_4_flat.jpg")
         return [download1, download2, download3]
    }

    func sampleDownloadsMutated() -> [Networking.ProductDownload] {
        let download1 = ProductDownload(downloadID: "1f9c11f99ceba63d4403c03bd5391b11",
                                        name: "Song #1",
                                        fileURL: "https://example.com/woo-single-1.ogg")
        let download2 = ProductDownload(downloadID: "ec87d8b5-1361-4562-b4b8-18980b5a2cae",
                                        name: "Artwork",
                                        fileURL: "https://example.com/cd_4_angle.jpg")
        return [download1, download2]
    }

    private func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}
