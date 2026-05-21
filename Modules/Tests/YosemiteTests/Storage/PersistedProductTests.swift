import Foundation
import Testing
import GRDB
@testable import Yosemite
@testable import Storage

struct PersistedProductTests {

    @Test("PersistedProduct init(from:) maps all POSProduct fields")
    func product_init_from_posProduct_maps_all_fields() throws {
        // Given
        let siteID: Int64 = 1
        let productID: Int64 = 10
        let posProduct = POSProduct(
            siteID: siteID,
            productID: productID,
            name: "Test Product",
            productTypeKey: "simple",
            fullDescription: "Full",
            shortDescription: "Short",
            sku: "SKU-123",
            globalUniqueID: "GID-1",
            price: "9.99",
            downloadable: false,
            parentID: 0,
            images: [],
            attributes: [],
            manageStock: true,
            stockQuantity: 5,
            stockStatusKey: "instock",
            statusKey: "publish",
            variationIDs: []
        )

        // When
        let persisted = PersistedProduct(from: posProduct)

        // Then
        #expect(persisted.id == productID)
        #expect(persisted.siteID == siteID)
        #expect(persisted.name == posProduct.name)
        #expect(persisted.productTypeKey == posProduct.productTypeKey)
        #expect(persisted.fullDescription == posProduct.fullDescription)
        #expect(persisted.shortDescription == posProduct.shortDescription)
        #expect(persisted.sku == posProduct.sku)
        #expect(persisted.globalUniqueID == posProduct.globalUniqueID)
        #expect(persisted.price == posProduct.price)
        #expect(persisted.downloadable == posProduct.downloadable)
        #expect(persisted.parentID == posProduct.parentID)
        #expect(persisted.manageStock == posProduct.manageStock)
        #expect(persisted.stockQuantity == posProduct.stockQuantity)
        #expect(persisted.stockStatusKey == posProduct.stockStatusKey)
        #expect(persisted.statusKey == posProduct.statusKey)
    }

    @Test("PersistedProduct toPOSProduct maps back with images and attributes")
    func product_toPOSProduct_maps_back_including_images_and_attributes() throws {
        // Given
        let siteID: Int64 = 2
        let productID: Int64 = 20
        let persisted = PersistedProduct(
            id: productID,
            siteID: siteID,
            name: "Prod",
            productTypeKey: "variable",
            fullDescription: "FullD",
            shortDescription: "ShortD",
            sku: nil,
            globalUniqueID: nil,
            price: "12.34",
            downloadable: true,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "outofstock",
            statusKey: "publish"
        )

        let productImages = [
            PersistedImage(siteID: siteID,
                          id: 200,
                          dateCreated: Date(timeIntervalSince1970: 10),
                          dateModified: nil,
                          src: "https://example.com/p1.png",
                          name: "p1",
                          alt: "a1"),
            PersistedImage(siteID: siteID,
                          id: 201,
                          dateCreated: Date(timeIntervalSince1970: 11),
                          dateModified: Date(timeIntervalSince1970: 12),
                          src: "https://example.com/p2.png",
                          name: nil,
                          alt: nil)
        ]

        let persistedAttributes = [
            PersistedProductAttribute(siteID: siteID,
                                      productID: productID,
                                      remoteAttributeID: 501,
                                      name: "Material",
                                      position: 0,
                                      visible: true,
                                      variation: false,
                                      options: ["Cotton"]),
            PersistedProductAttribute(siteID: siteID,
                                      productID: productID,
                                      remoteAttributeID: 502,
                                      name: "Fit",
                                      position: 1,
                                      visible: true,
                                      variation: true,
                                      options: ["Slim", "Regular"])
        ]

        // When
        let posProduct = persisted.toPOSProduct(
            images: productImages.map { $0.toProductImage() },
            attributes: persistedAttributes.map { $0.toProductAttribute(siteID: siteID) }
        )

        // Then
        #expect(posProduct.siteID == siteID)
        #expect(posProduct.productID == productID)
        #expect(posProduct.name == persisted.name)
        #expect(posProduct.productTypeKey == persisted.productTypeKey)
        #expect(posProduct.fullDescription == persisted.fullDescription)
        #expect(posProduct.shortDescription == persisted.shortDescription)
        #expect(posProduct.sku == persisted.sku)
        #expect(posProduct.globalUniqueID == persisted.globalUniqueID)
        #expect(posProduct.price == persisted.price)
        #expect(posProduct.downloadable == persisted.downloadable)
        #expect(posProduct.parentID == persisted.parentID)
        #expect(posProduct.manageStock == persisted.manageStock)
        #expect(posProduct.stockQuantity == persisted.stockQuantity)
        #expect(posProduct.stockStatusKey == persisted.stockStatusKey)
        #expect(posProduct.statusKey == persisted.statusKey)
        #expect(posProduct.images.count == 2)
        #expect(posProduct.attributes.count == 2)
        #expect(posProduct.attributesForVariations.count == 1)
    }

    @Test("A Product's images and attributes are fetched automatically")
    func product_with_associations_fetches_related_records() throws {
        // Given
        let grdbManager = try GRDBManager()
        let db = grdbManager.databaseConnection

        try db.write { db in
            // Insert test site first (required by foreign key)
            let site = PersistedSite(id: 1)
            try site.insert(db)

            // Insert test data
            let product = PersistedProduct(
                id: 100,
                siteID: 1,
                name: "Test Product",
                productTypeKey: "simple",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: "29.99",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "publish"
            )
            try product.insert(db)

            // Insert images into the image table
            let image1 = PersistedImage(
                siteID: 1,
                id: 200,
                dateCreated: Date(timeIntervalSince1970: 1000),
                dateModified: nil,
                src: "https://example.com/img1.png",
                name: "Image 1",
                alt: "Alt text 1"
            )
            let image2 = PersistedImage(
                siteID: 1,
                id: 201,
                dateCreated: Date(timeIntervalSince1970: 2000),
                dateModified: Date(timeIntervalSince1970: 2500),
                src: "https://example.com/img2.png",
                name: nil,
                alt: "Alt text 2"
            )
            try image1.insert(db)
            try image2.insert(db)

            // Create join table entries
            let productImage1 = PersistedProductImage(siteID: 1, productID: 100, imageID: 200)
            let productImage2 = PersistedProductImage(siteID: 1, productID: 100, imageID: 201)
            try productImage1.insert(db)
            try productImage2.insert(db)

            var attribute1 = PersistedProductAttribute(
                siteID: 1,
                productID: 100,
                remoteAttributeID: 501,
                name: "Color",
                position: 0,
                visible: true,
                variation: true,
                options: ["Red", "Blue", "Green"]
            )
            var attribute2 = PersistedProductAttribute(
                siteID: 1,
                productID: 100,
                remoteAttributeID: 502,
                name: "Size",
                position: 1,
                visible: false,
                variation: false,
                options: ["S", "M", "L"]
            )
            try attribute1.insert(db)
            try attribute2.insert(db)
        }

        // When the product is fetched and converted to a POSProduct
        let fetchedProduct = try db.read { db in
            try PersistedProduct.filter(PersistedProduct.Columns.id == 100).fetchOne(db)
        }

        let product = try #require(fetchedProduct)
        let posProduct = try product.toPOSProduct(db: db)

        // Then during conversion, images and attributes are populated via associations
        // Verify product
        #expect(posProduct.productID == 100)

        // Verify images were fetched
        #expect(posProduct.images.count == 2)
        let firstImage = posProduct.images.first { $0.imageID == 200 }
        #expect(firstImage?.src == "https://example.com/img1.png")
        #expect(firstImage?.name == "Image 1")
        #expect(firstImage?.alt == "Alt text 1")

        let secondImage = posProduct.images.first { $0.imageID == 201 }
        #expect(secondImage?.src == "https://example.com/img2.png")
        #expect(secondImage?.name == nil)
        #expect(secondImage?.alt == "Alt text 2")

        // Verify attributes were fetched
        #expect(posProduct.attributes.count == 2)
        let colorAttr = posProduct.attributes.first { $0.name == "Color" }
        #expect(colorAttr?.options == ["Red", "Blue", "Green"])
        #expect(colorAttr?.visible == true)
        #expect(colorAttr?.variation == true)

        let sizeAttr = posProduct.attributes.first { $0.name == "Size" }
        #expect(sizeAttr?.options == ["S", "M", "L"])
        #expect(sizeAttr?.visible == false)
        #expect(sizeAttr?.variation == false)
    }

    @Test("Product without related records has empty arrays")
    func product_without_related_records_creates_empty_arrays() throws {
        // Given a product without any images or attributes
        let grdbManager = try GRDBManager()
        let db = grdbManager.databaseConnection

        try db.write { db in
            // Insert site first
            let site = PersistedSite(id: 3)
            try site.insert(db)

            let product = PersistedProduct(
                id: 300,
                siteID: 3,
                name: "Lonely Product",
                productTypeKey: "simple",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: "5.00",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "publish"
            )
            try product.insert(db)
        }

        // When we retrieve and convert the product to a POSProduct
        let fetchedProduct = try db.read { db in
            try PersistedProduct.filter(PersistedProduct.Columns.id == 300).fetchOne(db)
        }

        let product = try #require(fetchedProduct)
        let posProduct = try product.toPOSProduct(db: db)

        // Then the POSProduct has empty arrays for images and attributes
        #expect(posProduct.productID == 300)
        #expect(posProduct.name == "Lonely Product")
        #expect(posProduct.images.isEmpty)
        #expect(posProduct.attributes.isEmpty)
    }

    @Test("PersistedProductAttribute init(from:) and toProductAttribute round-trip")
    func product_attribute_round_trip() throws {
        // Given
        let siteID: Int64 = 3
        let productID: Int64 = 30
        let attribute = ProductAttribute(siteID: siteID,
                                         attributeID: 0,
                                         name: "Flavor",
                                         position: 2,
                                         visible: true,
                                         variation: true,
                                         options: ["Vanilla", "Chocolate"])

        // When
        let persisted = PersistedProductAttribute(from: attribute, siteID: siteID, productID: productID)
        let back = persisted.toProductAttribute(siteID: siteID)

        // Then
        #expect(persisted.productID == productID)
        #expect(persisted.name == attribute.name)
        #expect(persisted.position == Int64(attribute.position))
        #expect(persisted.visible == attribute.visible)
        #expect(persisted.variation == attribute.variation)
        #expect(persisted.options == attribute.options)

        #expect(back.siteID == siteID)
        #expect(back.name == attribute.name)
        #expect(back.position == attribute.position)
        #expect(back.visible == attribute.visible)
        #expect(back.variation == attribute.variation)
        #expect(back.options == attribute.options)
    }

    @Test("PersistedProductAttribute with remoteAttributeID of 0 represents non-global attribute")
    func product_attribute_with_zero_remote_id_is_non_global() throws {
        // Given a non-global attribute (not shared across products)
        let siteID: Int64 = 10
        let productID: Int64 = 100
        let attribute = ProductAttribute(siteID: siteID,
                                         attributeID: 0,
                                         name: "Custom Color",
                                         position: 0,
                                         visible: true,
                                         variation: true,
                                         options: ["Custom Red", "Custom Blue"])

        // When
        let persisted = PersistedProductAttribute(from: attribute, siteID: siteID, productID: productID)

        // Then the remoteAttributeID should be 0 for non-global attributes
        #expect(persisted.remoteAttributeID == 0)
        #expect(persisted.name == "Custom Color")
        #expect(persisted.options == ["Custom Red", "Custom Blue"])

        // When converting back to ProductAttribute
        let back = persisted.toProductAttribute(siteID: siteID)

        // Then the attributeID should remain 0
        #expect(back.attributeID == 0)
        #expect(back.name == "Custom Color")
        #expect(back.options == ["Custom Red", "Custom Blue"])
    }

    @Test("Non-global product attribute persists and retrieves correctly with remoteAttributeID 0")
    func non_global_product_attribute_persists_correctly() throws {
        // Given
        let grdbManager = try GRDBManager()
        let db = grdbManager.databaseConnection

        try db.write { db in
            let site = PersistedSite(id: 5)
            try site.insert(db)

            let product = PersistedProduct(
                id: 500,
                siteID: 5,
                name: "Custom Product",
                productTypeKey: "variable",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: "25.00",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "publish"
            )
            try product.insert(db)

            // Insert a non-global attribute with remoteAttributeID = 0
            var nonGlobalAttribute = PersistedProductAttribute(
                siteID: 5,
                productID: 500,
                remoteAttributeID: 0,
                name: "Custom Texture",
                position: 0,
                visible: true,
                variation: true,
                options: ["Smooth", "Rough", "Textured"]
            )
            try nonGlobalAttribute.insert(db)

            // Also insert a global attribute for comparison
            var globalAttribute = PersistedProductAttribute(
                siteID: 5,
                productID: 500,
                remoteAttributeID: 123,
                name: "Standard Size",
                position: 1,
                visible: true,
                variation: false,
                options: ["Small", "Medium", "Large"]
            )
            try globalAttribute.insert(db)
        }

        // When
        let fetchedProduct = try db.read { db in
            try PersistedProduct.filter(PersistedProduct.Columns.id == 500).fetchOne(db)
        }

        let product = try #require(fetchedProduct)
        let posProduct = try product.toPOSProduct(db: db)

        // Then both attributes should be present
        #expect(posProduct.attributes.count == 2)

        // Verify non-global attribute
        let nonGlobalAttr = posProduct.attributes.first { $0.name == "Custom Texture" }
        #expect(nonGlobalAttr != nil)
        #expect(nonGlobalAttr?.attributeID == 0)
        #expect(nonGlobalAttr?.options == ["Smooth", "Rough", "Textured"])
        #expect(nonGlobalAttr?.variation == true)

        // Verify global attribute
        let globalAttr = posProduct.attributes.first { $0.name == "Standard Size" }
        #expect(globalAttr != nil)
        #expect(globalAttr?.attributeID == 123)
        #expect(globalAttr?.options == ["Small", "Medium", "Large"])
        #expect(globalAttr?.variation == false)
    }

    @Test("PersistedImage make(from:) and toProductImage round-trip")
    func product_image_round_trip() throws {
        // Given
        let image = ProductImage(imageID: 400,
                                 dateCreated: Date(timeIntervalSince1970: 100),
                                 dateModified: Date(timeIntervalSince1970: 200),
                                 src: "https://example.com/x.png",
                                 name: "x",
                                 alt: "y")

        // When
        let siteID: Int64 = 4
        let persisted = PersistedImage.make(from: image, siteID: siteID)
        let back = persisted.toProductImage()

        // Then
        #expect(persisted.id == image.imageID)
        #expect(persisted.siteID == siteID)
        #expect(persisted.dateCreated == image.dateCreated)
        #expect(persisted.dateModified == image.dateModified)
        #expect(persisted.src == image.src)
        #expect(persisted.name == image.name)
        #expect(persisted.alt == image.alt)

        #expect(back.imageID == image.imageID)
        #expect(back.dateCreated == image.dateCreated)
        #expect(back.dateModified == image.dateModified)
        #expect(back.src == image.src)
        #expect(back.name == image.name)
        #expect(back.alt == image.alt)
    }

    @Test("POSProduct.save() persists complete product with relationships")
    func save_persists_complete_pos_product() throws {
        let grdbManager = try GRDBManager()
        let db = grdbManager.databaseConnection

        // Setup site
        try db.write { db in
            let site = PersistedSite(id: 1)
            try site.insert(db)
        }

        // Given a complete POSProduct
        let posProduct = POSProduct(
            siteID: 1,
            productID: 123,
            name: "Complete Product",
            productTypeKey: "variable",
            fullDescription: "Complete description",
            shortDescription: "Short",
            sku: "COMPLETE-SKU",
            globalUniqueID: "GID-123",
            price: "99.99",
            downloadable: true,
            parentID: 0,
            images: [
                ProductImage(imageID: 1001, dateCreated: Date(), dateModified: nil, src: "https://example.com/1.png", name: "img1", alt: "alt1"),
                ProductImage(imageID: 1002, dateCreated: Date(), dateModified: nil, src: "https://example.com/2.png", name: "img2", alt: nil)
            ],
            attributes: [
                ProductAttribute(siteID: 1, attributeID: 0, name: "Color", position: 0, visible: true, variation: true, options: ["Red", "Blue"]),
                ProductAttribute(siteID: 1, attributeID: 0, name: "Size", position: 1, visible: true, variation: false, options: ["S", "M", "L"])
            ],
            manageStock: true,
            stockQuantity: 50,
            stockStatusKey: "instock",
            statusKey: "publish",
            variationIDs: []
        )

        // When saving and loading back
        try posProduct.save(to: db)

        let fetchedProduct = try db.read { db in
            // Split into two `filter` calls (they AND together): a single
            // compound predicate trips the Swift type-checker's complexity limit.
            try PersistedProduct.filter { $0.siteID == 1 }.filter { $0.id == 123 }.fetchOne(db)
        }
        let product = try #require(fetchedProduct)
        let loadedPOSProduct = try product.toPOSProduct(db: db)

        // Then all data should be preserved
        #expect(loadedPOSProduct.productID == posProduct.productID)
        #expect(loadedPOSProduct.name == posProduct.name)
        #expect(loadedPOSProduct.fullDescription == posProduct.fullDescription)
        #expect(loadedPOSProduct.shortDescription == posProduct.shortDescription)
        #expect(loadedPOSProduct.sku == posProduct.sku)
        #expect(loadedPOSProduct.images.count == 2)
        #expect(loadedPOSProduct.attributes.count == 2)

        // Verify images preserved
        let img1 = loadedPOSProduct.images.first { $0.imageID == 1001 }
        #expect(img1?.name == "img1")
        #expect(img1?.alt == "alt1")

        // Verify attributes preserved
        let colorAttr = loadedPOSProduct.attributes.first { $0.name == "Color" }
        #expect(colorAttr?.options == ["Red", "Blue"])
        #expect(colorAttr?.variation == true)
    }

    @Test("posProductsRequest filters out trashed products")
    func posProductsRequest_filters_out_trashed_products() throws {
        // Given
        let grdbManager = try GRDBManager()
        let db = grdbManager.databaseConnection

        try db.write { db in
            let site = PersistedSite(id: 1)
            try site.insert(db)

            // Insert a published product (should be included)
            let publishedProduct = PersistedProduct(
                id: 1,
                siteID: 1,
                name: "Published Product",
                productTypeKey: "simple",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: "10.00",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "publish"
            )
            try publishedProduct.insert(db)

            // Insert a trashed product (should be filtered out)
            let trashedProduct = PersistedProduct(
                id: 2,
                siteID: 1,
                name: "Trashed Product",
                productTypeKey: "simple",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: "20.00",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "trash"
            )
            try trashedProduct.insert(db)
        }

        // When
        let products = try db.read { db in
            try PersistedProduct.posProductsRequest(siteID: 1).fetchAll(db)
        }

        // Then
        #expect(products.count == 1)
        #expect(products.first?.name == "Published Product")
        #expect(products.first?.statusKey == "publish")
    }

    @Test("posProductsRequest filters out draft, and pending products")
    func posProductsRequest_filters_out_draft_pending_products() throws {
        // Given
        let grdbManager = try GRDBManager()
        let db = grdbManager.databaseConnection

        try db.write { db in
            let site = PersistedSite(id: 1)
            try site.insert(db)

            // Insert a published product (should be included)
            let publishedProduct = PersistedProduct(
                id: 1,
                siteID: 1,
                name: "Published Product",
                productTypeKey: "simple",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: "10.00",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "publish"
            )
            try publishedProduct.insert(db)

            // Insert draft product (should be filtered out)
            let draftProduct = PersistedProduct(
                id: 2,
                siteID: 1,
                name: "Draft Product",
                productTypeKey: "simple",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: "20.00",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "draft"
            )
            try draftProduct.insert(db)

            // Insert pending product (should be filtered out)
            let pendingProduct = PersistedProduct(
                id: 3,
                siteID: 1,
                name: "Pending Product",
                productTypeKey: "simple",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: "30.00",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "pending"
            )
            try pendingProduct.insert(db)
        }

        // When
        let products = try db.read { db in
            try PersistedProduct.posProductsRequest(siteID: 1).fetchAll(db)
        }

        // Then
        #expect(products.count == 1)
        #expect(products.first?.name == "Published Product")
    }

    @Test("posProductsRequest includes custom status products")
    func posProductsRequest_includes_custom_status_products() throws {
        // Given
        let grdbManager = try GRDBManager()
        let db = grdbManager.databaseConnection

        try db.write { db in
            let site = PersistedSite(id: 1)
            try site.insert(db)

            // Insert a published product
            let publishedProduct = PersistedProduct(
                id: 1,
                siteID: 1,
                name: "Published Product",
                productTypeKey: "simple",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: "10.00",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "publish"
            )
            try publishedProduct.insert(db)

            // Insert a product with custom status (should be included - 3rd party plugin)
            let customStatusProduct = PersistedProduct(
                id: 2,
                siteID: 1,
                name: "Custom Status Product",
                productTypeKey: "simple",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: "25.00",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "custom-status"
            )
            try customStatusProduct.insert(db)
        }

        // When
        let products = try db.read { db in
            try PersistedProduct.posProductsRequest(siteID: 1).fetchAll(db)
        }

        // Then both products should be included (custom status is not explicitly excluded)
        #expect(products.count == 2)
        let productNames = Set(products.map { $0.name })
        #expect(productNames.contains("Published Product"))
        #expect(productNames.contains("Custom Status Product"))
    }
}
