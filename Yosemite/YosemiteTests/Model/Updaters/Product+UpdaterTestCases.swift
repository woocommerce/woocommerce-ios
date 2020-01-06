import XCTest

@testable import Yosemite
@testable import Networking

final class Product_UpdaterTestCases: XCTestCase {
    func testUpdatingName() {
        let product = sampleProduct()
        let newName = "<p> cool product </p>"
        let updatedProduct = product.nameUpdated(name: newName)
        XCTAssertEqual(updatedProduct.name, newName)
        XCTAssertEqual(updatedProduct.fullDescription, product.fullDescription)
    }

    func testUpdatingDescription() {
        let product = sampleProduct()
        let newDescription = "<p> cool product </p>"
        let updatedProduct = product.descriptionUpdated(description: newDescription)
        XCTAssertEqual(updatedProduct.fullDescription, newDescription)
        XCTAssertEqual(updatedProduct.name, product.name)
    }

    func testUpdatingShippingSettings() {
        let product = sampleProduct()
        let newWeight = "9999"
        let newDimensions = ProductDimensions(length: "122", width: "333", height: "")
        let newShippingClass = ProductShippingClass(count: 2020,
                                                    descriptionHTML: "Arriving in 2 days!",
                                                    name: "2 Days",
                                                    shippingClassID: 2022,
                                                    siteID: product.siteID,
                                                    slug: "2-days")
        let updatedProduct = product.shippingSettingsUpdated(weight: newWeight, dimensions: newDimensions, shippingClass: newShippingClass)
        XCTAssertEqual(updatedProduct.fullDescription, product.fullDescription)
        XCTAssertEqual(updatedProduct.name, product.name)
        XCTAssertEqual(updatedProduct.weight, newWeight)
        XCTAssertEqual(updatedProduct.dimensions, newDimensions)
        XCTAssertEqual(updatedProduct.shippingClass, newShippingClass.slug)
        XCTAssertEqual(updatedProduct.shippingClassID, newShippingClass.shippingClassID)
        XCTAssertEqual(updatedProduct.productShippingClass, newShippingClass)
    }

    func testUpdatingInventorySettings() {
        let product = sampleProduct()
        let newSKU = "94115"
        let newManageStock = !product.manageStock
        let newSoldIndividually = !product.soldIndividually
        let newStockQuantity = 17
        let newBackordersSetting = ProductBackordersSetting.allowedAndNotifyCustomer
        let newStockStatus = ProductStockStatus.onBackOrder
        let updatedProduct = product.inventorySettingsUpdated(sku: newSKU,
                                                              manageStock: newManageStock,
                                                              soldIndividually: newSoldIndividually,
                                                              stockQuantity: newStockQuantity,
                                                              backordersSetting: newBackordersSetting,
                                                              stockStatus: newStockStatus)
        // Sanity check on unchanged properties.
        XCTAssertEqual(updatedProduct.fullDescription, product.fullDescription)
        XCTAssertEqual(updatedProduct.name, product.name)
        // Inventory settings.
        XCTAssertEqual(updatedProduct.sku, newSKU)
        XCTAssertEqual(updatedProduct.manageStock, newManageStock)
        XCTAssertEqual(updatedProduct.soldIndividually, newSoldIndividually)
        XCTAssertEqual(updatedProduct.stockQuantity, newStockQuantity)
        XCTAssertEqual(updatedProduct.backordersSetting, newBackordersSetting)
        XCTAssertEqual(updatedProduct.productStockStatus, newStockStatus)
    }
}

// MARK: - Private Helpers
//
private extension Product_UpdaterTestCases {

    func sampleProduct() -> Product {
        return Product(siteID: 123,
                       productID: 987,
                       name: "Book the Green Room",
                       slug: "book-the-green-room",
                       permalink: "https://example.com/product/book-the-green-room/",
                       dateCreated: date(with: "2019-02-19T17:33:31"),
                       dateModified: date(with: "2019-02-19T17:48:01"),
                       dateOnSaleStart: date(with: "2019-10-15T21:30:00"),
                       dateOnSaleEnd: date(with: "2019-10-27T21:29:59"),
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
                       productShippingClass: nil,
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

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}
