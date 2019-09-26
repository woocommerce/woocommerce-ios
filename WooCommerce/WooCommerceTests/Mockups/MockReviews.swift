import Foundation
@testable import Networking


final class MockReviews {
    let siteID          = 123
    let reviewID        = 1234
    let productID       = 12345
    let productName     = "Book the Green Room"
    let dateCreated     = Date()
    let statusKey       = "hold"
    let reviewer        = "A Human"
    let reviewerEmail   = "somewhere@on.the.internet.com"
    let reviewerAvatar  = "http://somewhere@on.the.internet.com"
    let reviewText      = "<p>A remarkable artifact</p>"
    let rating          = 4
    let verified        = true

    let sampleVariationTypeProductID = 295

    func review() -> Networking.ProductReview {
        return ProductReview(siteID: siteID,
                             reviewID: reviewID,
                             productID: productID,
                             dateCreated: dateCreated,
                             statusKey: statusKey,
                             reviewer: reviewer,
                             reviewerEmail: reviewerEmail,
                             reviewerAvatarURL: reviewerAvatar,
                             review: reviewText,
                             rating: rating,
                             verified: verified)
    }

    func anonyousReview() -> Networking.ProductReview {
        return ProductReview(siteID: siteID,
                             reviewID: reviewID,
                             productID: productID,
                             dateCreated: dateCreated,
                             statusKey: statusKey,
                             reviewer: "",
                             reviewerEmail: reviewerEmail,
                             reviewerAvatarURL: reviewerAvatar,
                             review: reviewText,
                             rating: rating,
                             verified: verified)
    }
}


extension MockReviews {
    func product(_ siteID: Int? = nil) -> Networking.Product {
        let testSiteID = siteID ?? self.siteID
        return Product(siteID: testSiteID,
                       productID: productID,
                       name: productName,
                       slug: "book-the-green-room",
                       permalink: "https://example.com/product/book-the-green-room/",
                       dateCreated: date(with: "2019-02-19T17:33:31"),
                       dateModified: date(with: "2019-02-19T17:48:01"),
                       productTypeKey: "booking",
                       statusKey: "publish",
                       featured: false,
                       catalogVisibilityKey: "visible",
                       fullDescription: "<p>This is the party room!</p>\n",
                       briefDescription: """
                           [contact-form]\n<p>The green room&#8217;s max capacity is 30 people. Reserving the date / time of your event is free. \
                           We can also accommodate large groups, with seating for 85 board game players at a time. If you have a large group, let us \
                           know and we&#8217;ll send you our large group rate.</p>\n<p>GROUP RATES</p>\n<p>Reserve your event for up to 30 guests \
                           for $100.</p>\n
                           """,
                       sku: "",
                       price: "0",
                       regularPrice: "",
                       salePrice: "",
                       onSale: false,
                       purchasable: true,
                       totalSales: 0,
                       virtual: true,
                       downloadable: false,
                       downloads: [],
                       downloadLimit: -1,
                       downloadExpiry: -1,
                       externalURL: "http://somewhere.com",
                       taxStatusKey: "taxable",
                       taxClass: "",
                       manageStock: false,
                       stockQuantity: nil,
                       stockStatusKey: "instock",
                       backordersKey: "no",
                       backordersAllowed: false,
                       backordered: false,
                       soldIndividually: true,
                       weight: "213",
                       dimensions: sampleDimensions(),
                       shippingRequired: false,
                       shippingTaxable: false,
                       shippingClass: "",
                       shippingClassID: 0,
                       reviewsAllowed: true,
                       averageRating: "4.30",
                       ratingCount: 23,
                       relatedIDs: [31, 22, 369, 414, 56],
                       upsellIDs: [99, 1234566],
                       crossSellIDs: [1234, 234234, 3],
                       parentID: 0,
                       purchaseNote: "Thank you!",
                       categories: sampleCategories(),
                       tags: sampleTags(),
                       images: sampleImages(),
                       attributes: sampleAttributes(),
                       defaultAttributes: sampleDefaultAttributes(),
                       variations: [192, 194, 193],
                       groupedProducts: [],
                       menuOrder: 0)
    }

    func sampleDimensions() -> Networking.ProductDimensions {
        return ProductDimensions(length: "12", width: "33", height: "54")
    }

    func sampleCategories() -> [Networking.ProductCategory] {
        let category1 = ProductCategory(categoryID: 36, name: "Events", slug: "events")
        return [category1]
    }

    func sampleTags() -> [Networking.ProductTag] {
        let tag1 = ProductTag(tagID: 37, name: "room", slug: "room")
        let tag2 = ProductTag(tagID: 38, name: "party room", slug: "party-room")
        let tag3 = ProductTag(tagID: 39, name: "30", slug: "30")
        let tag4 = ProductTag(tagID: 40, name: "20+", slug: "20")
        let tag5 = ProductTag(tagID: 41, name: "meeting room", slug: "meeting-room")
        let tag6 = ProductTag(tagID: 42, name: "meetings", slug: "meetings")
        let tag7 = ProductTag(tagID: 43, name: "parties", slug: "parties")
        let tag8 = ProductTag(tagID: 44, name: "graduation", slug: "graduation")
        let tag9 = ProductTag(tagID: 45, name: "birthday party", slug: "birthday-party")

        return [tag1, tag2, tag3, tag4, tag5, tag6, tag7, tag8, tag9]
    }

    func sampleImages() -> [Networking.ProductImage] {
        let image1 = ProductImage(imageID: 19,
                                  dateCreated: date(with: "2018-01-26T21:49:45"),
                                  dateModified: date(with: "2018-01-26T21:50:11"),
                                  src: "https://somewebsite.com/thuy-nonjtpk.mystagingwebsite.com/wp-content/uploads/2018/01/vneck-tee.jpg.png",
                                  name: "Vneck Tshirt",
                                  alt: "")
        return [image1]
    }

    func sampleAttributes() -> [Networking.ProductAttribute] {
        let attribute1 = ProductAttribute(attributeID: 0,
                                          name: "Color",
                                          position: 1,
                                          visible: true,
                                          variation: true,
                                          options: ["Purple", "Yellow", "Hot Pink", "Lime Green", "Teal"])

        let attribute2 = ProductAttribute(attributeID: 0,
                                          name: "Size",
                                          position: 0,
                                          visible: true,
                                          variation: true,
                                          options: ["Small", "Medium", "Large"])

        return [attribute1, attribute2]
    }

    func sampleDefaultAttributes() -> [Networking.ProductDefaultAttribute] {
        let defaultAttribute1 = ProductDefaultAttribute(attributeID: 0, name: "Color", option: "Purple")
        let defaultAttribute2 = ProductDefaultAttribute(attributeID: 0, name: "Size", option: "Medium")

        return [defaultAttribute1, defaultAttribute2]
    }

    func sampleDownloads() -> [Networking.ProductDownload] {
        let download1 = ProductDownload(downloadID: "1f9c11f99ceba63d4403c03bd5391b11",
                                        name: "Song #1",
                                        fileURL: "https://woocommerce.files.wordpress.com/2017/06/woo-single-1.ogg")
        let download2 = ProductDownload(downloadID: "ec87d8b5-1361-4562-b4b8-18980b5a2cae",
                                        name: "Artwork",
                                        fileURL: "https://thuy-test.mystagingwebsite.com/wp-content/uploads/2018/01/cd_4_angle.jpg")
        let download3 = ProductDownload(downloadID: "240cd543-5457-498e-95e2-6b51fdaf15cc",
                                        name: "Artwork 2",
                                        fileURL: "https://thuy-test.mystagingwebsite.com/wp-content/uploads/2018/01/cd_4_flat.jpg")
        return [download1, download2, download3]
    }

    func sampleProductMutated(_ siteID: Int? = nil) -> Networking.Product {
        let testSiteID = siteID ?? self.siteID

        return Product(siteID: testSiteID,
                       productID: productID,
                       name: productName,
                       slug: "book-the-green-room",
                       permalink: "https://example.com/product/book-the-green-room/",
                       dateCreated: date(with: "2019-02-19T17:33:31"),
                       dateModified: date(with: "2019-02-19T17:48:01"),
                       productTypeKey: "booking",
                       statusKey: "publish",
                       featured: false,
                       catalogVisibilityKey: "visible",
                       fullDescription: "<p>This is the party room!</p>\n",
                       briefDescription: """
                           [contact-form]\n<p>The green room&#8217;s max capacity is 30 people. Reserving the date / time of your event is free. \
                           We can also accommodate large groups, with seating for 85 board game players at a time. If you have a large group, let us \
                           know and we&#8217;ll send you our large group rate.</p>\n<p>GROUP RATES</p>\n<p>Reserve your event for up to 30 guests \
                           for $100.</p>\n
                           """,
                       sku: "345",
                       price: "123",
                       regularPrice: "",
                       salePrice: "",
                       onSale: true,
                       purchasable: false,
                       totalSales: 66,
                       virtual: false,
                       downloadable: true,
                       downloads: sampleDownloads(),
                       downloadLimit: 1,
                       downloadExpiry: 1,
                       externalURL: "http://somewhere.com.net",
                       taxStatusKey: "taxable",
                       taxClass: "",
                       manageStock: true,
                       stockQuantity: nil,
                       stockStatusKey: "nostock",
                       backordersKey: "yes",
                       backordersAllowed: true,
                       backordered: true,
                       soldIndividually: false,
                       weight: "777",
                       dimensions: sampleDimensionsMutated(),
                       shippingRequired: true,
                       shippingTaxable: false,
                       shippingClass: "",
                       shippingClassID: 0,
                       reviewsAllowed: false,
                       averageRating: "1.30",
                       ratingCount: 76,
                       relatedIDs: [31, 22, 369],
                       upsellIDs: [99, 123, 234, 444],
                       crossSellIDs: [1234, 234234, 999, 989],
                       parentID: 444,
                       purchaseNote: "Whatever!",
                       categories: sampleCategoriesMutated(),
                       tags: sampleTagsMutated(),
                       images: sampleImagesMutated(),
                       attributes: sampleAttributesMutated(),
                       defaultAttributes: sampleDefaultAttributesMutated(),
                       variations: [],
                       groupedProducts: [111, 222, 333],
                       menuOrder: 0)
    }

    func sampleDimensionsMutated() -> Networking.ProductDimensions {
        return ProductDimensions(length: "12", width: "33", height: "54")
    }

    func sampleCategoriesMutated() -> [Networking.ProductCategory] {
        let category1 = ProductCategory(categoryID: 36, name: "Events", slug: "events")
        let category2 = ProductCategory(categoryID: 362, name: "Other Stuff", slug: "other")
        return [category1, category2]
    }

    func sampleTagsMutated() -> [Networking.ProductTag] {
        let tag1 = ProductTag(tagID: 37, name: "something", slug: "something")
        let tag2 = ProductTag(tagID: 38, name: "party room", slug: "party-room")
        let tag3 = ProductTag(tagID: 39, name: "3000", slug: "3000")
        let tag4 = ProductTag(tagID: 45, name: "birthday party", slug: "birthday-party")
        let tag5 = ProductTag(tagID: 95, name: "yep", slug: "yep")

        return [tag1, tag2, tag3, tag4, tag5]
    }

    func sampleImagesMutated() -> [Networking.ProductImage] {
        let image1 = ProductImage(imageID: 19,
                                  dateCreated: date(with: "2018-01-26T21:49:45"),
                                  dateModified: date(with: "2018-01-26T21:50:11"),
                                  src: "https://somewebsite.com/thuy-nonjtpk.mystagingwebsite.com/wp-content/uploads/2018/01/vneck-tee.jpg.png",
                                  name: "Vneck Tshirt",
                                  alt: "")
        let image2 = ProductImage(imageID: 999,
                                  dateCreated: date(with: "2019-01-26T21:44:45"),
                                  dateModified: date(with: "2019-01-26T21:54:11"),
                                  src: "https://somewebsite.com/thuy-nonjtpk.mystagingwebsite.com/wp-content/uploads/2018/01/test.png",
                                  name: "ZZZTest Image",
                                  alt: "")
        return [image1, image2]
    }

    func sampleAttributesMutated() -> [Networking.ProductAttribute] {
        let attribute1 = ProductAttribute(attributeID: 0,
                                          name: "Color",
                                          position: 0,
                                          visible: false,
                                          variation: false,
                                          options: ["Purple", "Yellow"])

        return [attribute1]
    }

    func sampleDefaultAttributesMutated() -> [Networking.ProductDefaultAttribute] {
        let defaultAttribute1 = ProductDefaultAttribute(attributeID: 0, name: "Color", option: "Purple")

        return [defaultAttribute1]
    }

    func sampleVariationTypeProduct(_ siteID: Int? = nil) -> Networking.Product {
        let testSiteID = siteID ?? self.siteID
        return Product(siteID: testSiteID,
                       productID: sampleVariationTypeProductID,
                       name: "Paper Airplane - Black, Long",
                       slug: "paper-airplane-3",
                       permalink: "https://paperairplane.store/product/paper-airplane/?attribute_color=Black&attribute_length=Long",
                       dateCreated: date(with: "2019-04-04T22:06:45"),
                       dateModified: date(with: "2019-04-09T20:24:03"),
                       productTypeKey: "variation",
                       statusKey: "publish",
                       featured: false,
                       catalogVisibilityKey: "visible",
                       fullDescription: "<p>Long paper airplane. Color is black. </p>\n",
                       briefDescription: "",
                       sku: "345345-2",
                       price: "22.72",
                       regularPrice: "22.72",
                       salePrice: "",
                       onSale: false,
                       purchasable: true,
                       totalSales: 0,
                       virtual: false,
                       downloadable: false,
                       downloads: [],
                       downloadLimit: -1,
                       downloadExpiry: -1,
                       externalURL: "",
                       taxStatusKey: "taxable",
                       taxClass: "",
                       manageStock: true,
                       stockQuantity: nil,
                       stockStatusKey: "instock",
                       backordersKey: "no",
                       backordersAllowed: false,
                       backordered: false,
                       soldIndividually: true,
                       weight: "888",
                       dimensions: sampleVariationTypeDimensions(),
                       shippingRequired: true,
                       shippingTaxable: true,
                       shippingClass: "",
                       shippingClassID: 0,
                       reviewsAllowed: true,
                       averageRating: "0.00",
                       ratingCount: 0,
                       relatedIDs: [],
                       upsellIDs: [],
                       crossSellIDs: [],
                       parentID: 205,
                       purchaseNote: "",
                       categories: [],
                       tags: [],
                       images: sampleVariationTypeImages(),
                       attributes: sampleVariationTypeAttributes(),
                       defaultAttributes: [],
                       variations: [],
                       groupedProducts: [],
                       menuOrder: 2)
    }

    func sampleVariationTypeDimensions() -> Networking.ProductDimensions {
        return ProductDimensions(length: "11", width: "22", height: "33")
    }

    func sampleVariationTypeImages() -> [Networking.ProductImage] {
        let image1 = ProductImage(imageID: 301,
                                  dateCreated: date(with: "2019-04-09T20:23:58"),
                                  dateModified: date(with: "2019-04-09T20:23:58"),
                                  src: "https://i0.wp.com/paperairplane.store/wp-content/uploads/2019/04/paper_plane_black.png?fit=600%2C473&ssl=1",
                                  name: "paper_plane_black",
                                  alt: "")
        return [image1]
    }

    func sampleVariationTypeAttributes() -> [Networking.ProductAttribute] {
        let attribute1 = ProductAttribute(attributeID: 0,
                                          name: "Color",
                                          position: 0,
                                          visible: true,
                                          variation: true,
                                          options: ["Black"])

        let attribute2 = ProductAttribute(attributeID: 0,
                                          name: "Length",
                                          position: 0,
                                          visible: true,
                                          variation: true,
                                          options: ["Long"])

        return [attribute1, attribute2]
    }

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }

}
