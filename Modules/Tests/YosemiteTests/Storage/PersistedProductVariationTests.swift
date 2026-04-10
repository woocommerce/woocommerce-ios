import Foundation
import Testing
import GRDB
@testable import Yosemite
@testable import Storage

struct PersistedProductVariationTests {

    @Test("PersistedProductVariation init(from:) maps all POSProductVariation fields")
    func variation_init_from_posProductVariation_maps_all_fields() throws {
        // Given
        let siteID: Int64 = 5
        let productID: Int64 = 50
        let variationID: Int64 = 500
        let attrs = [
            ProductVariationAttribute(id: 0, name: "Color", option: "Green"),
            ProductVariationAttribute(id: 0, name: "Size", option: "XL")
        ]
        let image = ProductImage(imageID: 501,
                                 dateCreated: Date(timeIntervalSince1970: 1000),
                                 dateModified: nil,
                                 src: "https://example.com/v.png",
                                 name: "v",
                                 alt: nil)
        let pos = POSProductVariation(
            siteID: siteID,
            productID: productID,
            productVariationID: variationID,
            attributes: attrs,
            image: image,
            fullDescription: "VFull",
            sku: "VSKU",
            globalUniqueID: "VGID",
            price: "19.95",
            downloadable: false,
            manageStock: true,
            stockQuantity: 2,
            stockStatusKey: "instock"
        )

        // When
        let persisted = PersistedProductVariation(from: pos)

        // Then
        #expect(persisted.id == variationID)
        #expect(persisted.siteID == siteID)
        #expect(persisted.productID == productID)
        #expect(persisted.sku == pos.sku)
        #expect(persisted.globalUniqueID == pos.globalUniqueID)
        #expect(persisted.price == pos.price)
        #expect(persisted.downloadable == pos.downloadable)
        #expect(persisted.fullDescription == pos.fullDescription)
        #expect(persisted.manageStock == pos.manageStock)
        #expect(persisted.stockQuantity == pos.stockQuantity)
        #expect(persisted.stockStatusKey == pos.stockStatusKey)
    }

    @Test("PersistedProductVariation toPOSProductVariation maps back with attributes and optional image")
    func variation_toPOSProductVariation_maps_back_including_attributes_and_image() throws {
        // Given
        let siteID: Int64 = 6
        let productID: Int64 = 60
        let variationID: Int64 = 600
        let persisted = PersistedProductVariation(
            id: variationID,
            siteID: siteID,
            productID: productID,
            sku: "SKU",
            globalUniqueID: "GID",
            price: "11.00",
            downloadable: true,
            fullDescription: "Full",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "outofstock"
        )

        let varAttrs = [
            PersistedProductVariationAttribute(siteID: siteID,
                                               productVariationID: variationID,
                                               remoteAttributeID: 100,
                                               name: "Material",
                                               option: "Wool"),
            PersistedProductVariationAttribute(siteID: siteID,
                                               productVariationID: variationID,
                                               remoteAttributeID: 101,
                                               name: "Fit",
                                               option: "Slim")
        ]
        let varImage = PersistedImage(
            siteID: siteID,
            id: 601,
            dateCreated: Date(timeIntervalSince1970: 2000),
            dateModified: Date(timeIntervalSince1970: 3000),
            src: "https://example.com/vi.png",
            name: "vi",
            alt: "vai")

        // When
        let pos = persisted.toPOSProductVariation(
            attributes: varAttrs.map { $0.toProductVariationAttribute() },
            image: varImage.toProductImage()
        )

        // Then
        #expect(pos.siteID == siteID)
        #expect(pos.productID == productID)
        #expect(pos.productVariationID == variationID)
        #expect(pos.sku == persisted.sku)
        #expect(pos.globalUniqueID == persisted.globalUniqueID)
        #expect(pos.price == persisted.price)
        #expect(pos.downloadable == persisted.downloadable)
        #expect(pos.fullDescription == persisted.fullDescription)
        #expect(pos.manageStock == persisted.manageStock)
        #expect(pos.stockQuantity == persisted.stockQuantity)
        #expect(pos.stockStatusKey == persisted.stockStatusKey)
        #expect(pos.attributes.count == 2)
        #expect(pos.image?.imageID == varImage.id)
    }

    @Test("ProductVariation with associations fetches attributes and image automatically")
    func product_variation_with_associations_fetches_related_records() throws {
        // Given a persisted variation with associations
        let grdbManager = try GRDBManager()
        let db = grdbManager.databaseConnection

        try db.write { db in
            // Insert required site and product first
            let site = PersistedSite(id: 2)
            try site.insert(db)

            let parentProduct = PersistedProduct(
                id: 50,
                siteID: 2,
                name: "Parent Product",
                productTypeKey: "variable",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: "0.00",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "publish"
            )
            try parentProduct.insert(db)

            // Insert test data
            let variation = PersistedProductVariation(
                id: 500,
                siteID: 2,
                productID: 50,
                sku: "VAR-SKU",
                globalUniqueID: "GID-500",
                price: "15.50",
                downloadable: true,
                fullDescription: "Variation description",
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "outofstock"
            )
            try variation.insert(db)

            // Insert image into image table
            let variationImage = PersistedImage(
                siteID: 2,
                id: 600,
                dateCreated: Date(timeIntervalSince1970: 3000),
                dateModified: Date(timeIntervalSince1970: 3500),
                src: "https://example.com/var-img.png",
                name: "Variation Image",
                alt: "Variation alt text"
            )
            try variationImage.insert(db)

            // Create join table entry
            let variationImageJoin = PersistedProductVariationImage(siteID: 2, productVariationID: 500, imageID: 600)
            try variationImageJoin.insert(db)

            var attr1 = PersistedProductVariationAttribute(
                siteID: 2,
                productVariationID: 500,
                remoteAttributeID: 502,
                name: "Color",
                option: "Purple"
            )
            var attr2 = PersistedProductVariationAttribute(
                siteID: 2,
                productVariationID: 500,
                remoteAttributeID: 503,
                name: "Material",
                option: "Cotton"
            )
            try attr1.insert(db)
            try attr2.insert(db)
        }

        // When we fetch it, specifying inclusion of image and attributes
        struct DetailedVariation: Decodable, FetchableRecord {
            var variation: PersistedProductVariation
            var image: PersistedImage
            var attributes: [PersistedProductVariationAttribute]

            enum CodingKeys: CodingKey {
                case variation
                case image
                case attributes
            }
        }

        let fetchedVariation = try db.read { db in
            try PersistedProductVariation
                .including(optional: PersistedProductVariation.image)
                .including(all: PersistedProductVariation.attributes)
                .asRequest(of: DetailedVariation.self)
                .fetchAll(db)
        }.first

        // Verify variation fields
        #expect(fetchedVariation?.variation.id == 500)
        #expect(fetchedVariation?.variation.siteID == 2)
        #expect(fetchedVariation?.variation.productID == 50)
        #expect(fetchedVariation?.variation.sku == "VAR-SKU")
        #expect(fetchedVariation?.variation.fullDescription == "Variation description")
        #expect(fetchedVariation?.variation.price == "15.50")
        #expect(fetchedVariation?.variation.downloadable == true)
        #expect(fetchedVariation?.variation.manageStock == false)
        #expect(fetchedVariation?.variation.stockQuantity == nil)
        #expect(fetchedVariation?.variation.stockStatusKey == "outofstock")

        // Then the image and attributes are included in the fetched data
        // Verify image was fetched
        #expect(fetchedVariation?.image.id == 600)
        #expect(fetchedVariation?.image.src == "https://example.com/var-img.png")
        #expect(fetchedVariation?.image.name == "Variation Image")
        #expect(fetchedVariation?.image.alt == "Variation alt text")

        // Verify attributes were fetched
        #expect(fetchedVariation?.attributes.count == 2)
        let colorAttr = fetchedVariation?.attributes.first { $0.name == "Color" }
        #expect(colorAttr?.option == "Purple")

        let materialAttr = fetchedVariation?.attributes.first { $0.name == "Material" }
        #expect(materialAttr?.option == "Cotton")
    }

    @Test("ProductVariation without image returns nil image")
    func product_variation_without_image_returns_nil() throws {
        // Given a persisted variation without an image
        let grdbManager = try GRDBManager()
        let db = grdbManager.databaseConnection

        try db.write { db in
            // Insert required site and product first
            let site = PersistedSite(id: 4)
            try site.insert(db)

            let parentProduct = PersistedProduct(
                id: 70,
                siteID: 4,
                name: "Parent Product",
                productTypeKey: "variable",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: "0.00",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "publish"
            )
            try parentProduct.insert(db)

            // Insert variation with attributes but no image
            let variation = PersistedProductVariation(
                id: 700,
                siteID: 4,
                productID: 70,
                sku: "VAR-NO-IMG",
                globalUniqueID: "GID-700",
                price: "12.00",
                downloadable: false,
                fullDescription: "No image variation",
                manageStock: true,
                stockQuantity: 3,
                stockStatusKey: "instock"
            )
            try variation.insert(db)

            // Add attributes only, no image
            var attr = PersistedProductVariationAttribute(
                siteID: 4,
                productVariationID: 700,
                remoteAttributeID: 105,
                name: "Style",
                option: "Modern"
            )
            try attr.insert(db)
        }

        // When we fetch that variation
        let fetchedVariation = try db.read { db in
            try PersistedProductVariation.filter(PersistedProductVariation.Columns.id == 700).fetchOne(db)
        }

        let variation = try #require(fetchedVariation)
        let posVariation = try variation.toPOSProductVariation(db: db)

        // Then the image is nil
        #expect(posVariation.productVariationID == 700)
        #expect(posVariation.image == nil)
        #expect(posVariation.attributes.count == 1)
        #expect(posVariation.attributes.first?.name == "Style")
        #expect(posVariation.attributes.first?.option == "Modern")
    }

    @Test("PersistedProductVariationAttribute init(from:) and toProductVariationAttribute round-trip")
    func variation_attribute_round_trip() throws {
        // Given
        let variationID: Int64 = 700
        let attr = ProductVariationAttribute(id: 0, name: "Style", option: "Modern")

        // When
        let siteID: Int64 = 7
        let persisted = PersistedProductVariationAttribute(from: attr, siteID: siteID, productVariationID: variationID)
        let back = persisted.toProductVariationAttribute()

        // Then
        #expect(persisted.productVariationID == variationID)
        #expect(persisted.name == attr.name)
        #expect(persisted.option == attr.option)

        #expect(back.name == attr.name)
        #expect(back.option == attr.option)
    }

    @Test("ProductVariationAttribute with remoteAttributeID of 0 represents non-global attribute")
    func variation_attribute_with_zero_remote_id_is_non_global() throws {
        // Given a non-global variation attribute (not shared across variations)
        let siteID: Int64 = 20
        let variationID: Int64 = 2000
        let attr = ProductVariationAttribute(id: 0, name: "Custom Finish", option: "Matte")

        // When
        let persisted = PersistedProductVariationAttribute(from: attr, siteID: siteID, productVariationID: variationID)

        // Then the remoteAttributeID should be 0 for non-global attributes
        #expect(persisted.remoteAttributeID == 0)
        #expect(persisted.name == "Custom Finish")
        #expect(persisted.option == "Matte")

        // When converting back to ProductVariationAttribute
        let back = persisted.toProductVariationAttribute()

        // Then the id should remain 0
        #expect(back.id == 0)
        #expect(back.name == "Custom Finish")
        #expect(back.option == "Matte")
    }

    @Test("Non-global variation attribute persists and retrieves correctly with remoteAttributeID 0")
    func non_global_variation_attribute_persists_correctly() throws {
        // Given
        let grdbManager = try GRDBManager()
        let db = grdbManager.databaseConnection

        try db.write { db in
            let site = PersistedSite(id: 6)
            try site.insert(db)

            let parentProduct = PersistedProduct(
                id: 600,
                siteID: 6,
                name: "Parent Product with Variations",
                productTypeKey: "variable",
                fullDescription: nil,
                shortDescription: nil,
                sku: nil,
                globalUniqueID: nil,
                price: "0.00",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "publish"
            )
            try parentProduct.insert(db)

            let variation = PersistedProductVariation(
                id: 6000,
                siteID: 6,
                productID: 600,
                sku: "VAR-6000",
                globalUniqueID: nil,
                price: "30.00",
                downloadable: false,
                fullDescription: nil,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock"
            )
            try variation.insert(db)

            // Insert a non-global variation attribute with remoteAttributeID = 0
            var nonGlobalAttribute = PersistedProductVariationAttribute(
                siteID: 6,
                productVariationID: 6000,
                remoteAttributeID: 0,
                name: "Custom Pattern",
                option: "Striped"
            )
            try nonGlobalAttribute.insert(db)

            // Also insert a global variation attribute for comparison
            var globalAttribute = PersistedProductVariationAttribute(
                siteID: 6,
                productVariationID: 6000,
                remoteAttributeID: 456,
                name: "Standard Color",
                option: "Navy"
            )
            try globalAttribute.insert(db)
        }

        // When
        let fetchedVariation = try db.read { db in
            try PersistedProductVariation.filter(PersistedProductVariation.Columns.id == 6000).fetchOne(db)
        }

        let variation = try #require(fetchedVariation)
        let posVariation = try variation.toPOSProductVariation(db: db)

        // Then both attributes should be present
        #expect(posVariation.attributes.count == 2)

        // Verify non-global attribute
        let nonGlobalAttr = posVariation.attributes.first { $0.name == "Custom Pattern" }
        #expect(nonGlobalAttr != nil)
        #expect(nonGlobalAttr?.id == 0)
        #expect(nonGlobalAttr?.option == "Striped")

        // Verify global attribute
        let globalAttr = posVariation.attributes.first { $0.name == "Standard Color" }
        #expect(globalAttr != nil)
        #expect(globalAttr?.id == 456)
        #expect(globalAttr?.option == "Navy")
    }

    @Test("PersistedImage make(from:) and toProductImage round-trip for variation")
    func variation_image_round_trip() throws {
        // Given
        let image = ProductImage(imageID: 801,
                                 dateCreated: Date(timeIntervalSince1970: 4000),
                                 dateModified: nil,
                                 src: "https://example.com/img.png",
                                 name: nil,
                                 alt: nil)

        // When
        let siteID: Int64 = 8
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

    @Test("POSProductVariation.save() persists complete variation with relationships")
    func save_persists_complete_pos_product_variation() throws {
        let grdbManager = try GRDBManager()
        let db = grdbManager.databaseConnection

        // Setup site and parent product
        try db.write { db in
            let site = PersistedSite(id: 1)
            try site.insert(db)

            let parentProduct = PersistedProduct(
                id: 200,
                siteID: 1,
                name: "Parent Product",
                productTypeKey: "variable",
                fullDescription: nil,
                shortDescription: nil,
                sku: "PARENT-SKU",
                globalUniqueID: nil,
                price: "0.00",
                downloadable: false,
                parentID: 0,
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: "instock",
                statusKey: "publish"
            )
            try parentProduct.insert(db)
        }

        // Given a complete POSProductVariation
        let posVariation = POSProductVariation(
            siteID: 1,
            productID: 200,
            productVariationID: 456,
            attributes: [
                ProductVariationAttribute(id: 0, name: "Color", option: "Red"),
                ProductVariationAttribute(id: 0, name: "Size", option: "Large")
            ],
            image: ProductImage(imageID: 2001,
                                dateCreated: Date(),
                                dateModified: nil,
                                src: "https://example.com/var.png",
                                name: "var-img",
                                alt: "variation image"),
            fullDescription: "Complete variation description",
            sku: "VAR-COMPLETE-SKU",
            globalUniqueID: "GID-456",
            price: "149.99",
            downloadable: false,
            manageStock: true,
            stockQuantity: 25,
            stockStatusKey: "instock"
        )

        // When saving and loading back
        try posVariation.save(to: db)

        let fetchedVariation = try db.read { db in
            try PersistedProductVariation.filter(PersistedProductVariation.Columns.id == 456).fetchOne(db)
        }
        let variation = try #require(fetchedVariation)
        let loadedPOSVariation = try variation.toPOSProductVariation(db: db)

        // Then all data should be preserved
        #expect(loadedPOSVariation.productVariationID == posVariation.productVariationID)
        #expect(loadedPOSVariation.productID == posVariation.productID)
        #expect(loadedPOSVariation.siteID == posVariation.siteID)
        #expect(loadedPOSVariation.fullDescription == posVariation.fullDescription)
        #expect(loadedPOSVariation.sku == posVariation.sku)
        #expect(loadedPOSVariation.price == posVariation.price)
        #expect(loadedPOSVariation.stockQuantity == posVariation.stockQuantity)
        #expect(loadedPOSVariation.attributes.count == 2)
        #expect(loadedPOSVariation.image != nil)

        // Verify image preserved
        #expect(loadedPOSVariation.image?.imageID == 2001)
        #expect(loadedPOSVariation.image?.name == "var-img")
        #expect(loadedPOSVariation.image?.alt == "variation image")

        // Verify attributes preserved
        let colorAttr = loadedPOSVariation.attributes.first { $0.name == "Color" }
        #expect(colorAttr?.option == "Red")

        let sizeAttr = loadedPOSVariation.attributes.first { $0.name == "Size" }
        #expect(sizeAttr?.option == "Large")
    }
}
