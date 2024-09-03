import XCTest
import CoreData

@testable import Storage

/// Tests for migrating from a specific model version to another.
///
/// Ideally, we should have a test for every new model version. There can also be more than
/// one test between 2 versions if there are many cases being tested.
///
/// ## Notes
///
/// In general, we should avoid using the entity classes like `Product` or `Order`. These classes
/// may **change** in the future. And if they do, the migration tests would have to be changed.
/// There's a risk that the migration tests would no longer be correct if this happens.
///
/// That said, it is understandable that we are sometimes under pressure to finish features that
/// this may not be economical.
///
final class MigrationTests: XCTestCase {
    private var modelsInventory: ManagedObjectModelsInventory!

    /// URLs of SQLite stores created using `makePersistentStore()`.
    ///
    /// These will be deleted during tear down.
    private var createdStoreURLs = Set<URL>()

    override func setUpWithError() throws {
        try super.setUpWithError()
        modelsInventory = try .from(packageName: "WooCommerce", bundle: Bundle(for: CoreDataManager.self))
    }

    override func tearDownWithError() throws {
        let fileManager = FileManager.default
        let knownExtensions = ["sqlite-shm", "sqlite-wal"]
        try createdStoreURLs.forEach { url in
            try fileManager.removeItem(at: url)

            try knownExtensions.forEach { ext in
                if fileManager.fileExists(atPath: url.appendingPathExtension(ext).path) {
                    try fileManager.removeItem(at: url.appendingPathExtension(ext))
                }
            }
        }

        modelsInventory = nil

        try super.tearDownWithError()
    }

    func test_migrating_from_26_to_27_deletes_ProductCategory_objects() throws {
        // Arrange
        let sourceContainer = try startPersistentContainer("Model 26")
        let sourceContext = sourceContainer.viewContext

        insertAccount(to: sourceContext)
        let product = insertProduct(to: sourceContext, forModel: 26)
        let productCategory = insertProductCategory(to: sourceContext)
        product.mutableSetValue(forKey: "categories").add(productCategory)

        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "Account"), 1)
        XCTAssertEqual(try sourceContext.count(entityName: "Product"), 1)
        XCTAssertEqual(try sourceContext.count(entityName: "ProductCategory"), 1)

        // Action
        let targetContainer = try migrate(sourceContainer, to: "Model 27")
        let targetContext = targetContainer.viewContext

        // Assert
        XCTAssertEqual(try targetContext.count(entityName: "Account"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "Product"), 1)
        // Product categories should be deleted.
        XCTAssertEqual(try targetContext.count(entityName: "ProductCategory"), 0)
    }

    func test_migrating_from_28_to_29_deletes_ProductTag_objects() throws {
        // Arrange
        let sourceContainer = try startPersistentContainer("Model 28")
        let sourceContext = sourceContainer.viewContext

        insertAccount(to: sourceContext)
        let product = insertProduct(to: sourceContext, forModel: 28)
        let productTag = insertProductTag(to: sourceContext)
        product.mutableSetValue(forKey: "tags").add(productTag)

        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "Account"), 1)
        XCTAssertEqual(try sourceContext.count(entityName: "Product"), 1)
        XCTAssertEqual(try sourceContext.count(entityName: "ProductTag"), 1)

        // Action
        let targetContainer = try migrate(sourceContainer, to: "Model 29")

        // Assert
        let targetContext = targetContainer.viewContext
        XCTAssertEqual(try targetContext.count(entityName: "Account"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "Product"), 1)
        // Product tags should be deleted.
        XCTAssertEqual(try targetContext.count(entityName: "ProductTag"), 0)
    }

    func test_migrating_from_20_to_28_will_keep_transformable_attributes() throws {
        // Arrange
        let sourceContainer = try startPersistentContainer("Model 20")
        let sourceContext = sourceContainer.viewContext

        let product = insertProduct(to: sourceContext, forModel: 20)
        // Populates transformable attributes.
        let productCrossSellIDs: [Int64] = [630, 688]
        let groupedProductIDs: [Int64] = [94, 134]
        let productRelatedIDs: [Int64] = [270, 37]
        let productUpsellIDs: [Int64] = [1126, 1216]
        let productVariationIDs: [Int64] = [927, 1110]
        product.setValue(productCrossSellIDs, forKey: "crossSellIDs")
        product.setValue(groupedProductIDs, forKey: "groupedProducts")
        product.setValue(productRelatedIDs, forKey: "relatedIDs")
        product.setValue(productUpsellIDs, forKey: "upsellIDs")
        product.setValue(productVariationIDs, forKey: "variations")

        let productAttribute = insertProductAttribute(to: sourceContext)
        // Populates transformable attributes.
        let attributeOptions = ["Woody", "Andy Panda"]
        productAttribute.setValue(attributeOptions, forKey: "options")

        product.mutableSetValue(forKey: "attributes").add(productAttribute)

        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "Product"), 1)
        XCTAssertEqual(try sourceContext.count(entityName: "ProductAttribute"), 1)

        // Action
        let targetContainer = try migrate(sourceContainer, to: "Model 28")

        // Assert
        let targetContext = targetContainer.viewContext

        let persistedProduct = try XCTUnwrap(targetContext.first(entityName: "Product"))
        XCTAssertEqual(persistedProduct.value(forKey: "crossSellIDs") as? [Int64], productCrossSellIDs)
        XCTAssertEqual(persistedProduct.value(forKey: "groupedProducts") as? [Int64], groupedProductIDs)
        XCTAssertEqual(persistedProduct.value(forKey: "relatedIDs") as? [Int64], productRelatedIDs)
        XCTAssertEqual(persistedProduct.value(forKey: "upsellIDs") as? [Int64], productUpsellIDs)
        XCTAssertEqual(persistedProduct.value(forKey: "variations") as? [Int64], productVariationIDs)

        let persistedAttribute = try XCTUnwrap(targetContext.first(entityName: "ProductAttribute"))
        XCTAssertEqual(persistedAttribute.value(forKey: "options") as? [String], attributeOptions)
    }

    func test_migrating_from_31_to_32_renames_Attribute_to_GenericAttribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 31")
        let sourceContext = sourceContainer.viewContext

        let attribute = sourceContext.insert(entityName: "Attribute", properties: [
            "id": 9_753_134,
            "key": "voluptatem",
            "value": "veritatis"
        ])
        let variation = insertProductVariation(to: sourceContainer.viewContext)
        variation.mutableOrderedSetValue(forKey: "attributes").add(attribute)

        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "Attribute"), 1)
        XCTAssertEqual(try sourceContext.count(entityName: "ProductVariation"), 1)

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 32")

        // Then
        let targetContext = targetContainer.viewContext

        XCTAssertNil(NSEntityDescription.entity(forEntityName: "Attribute", in: targetContext))
        XCTAssertEqual(try targetContext.count(entityName: "GenericAttribute"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "ProductVariation"), 1)

        let migratedAttribute = try XCTUnwrap(targetContext.allObjects(entityName: "GenericAttribute").first)
        XCTAssertEqual(migratedAttribute.value(forKey: "id") as? Int, 9_753_134)
        XCTAssertEqual(migratedAttribute.value(forKey: "key") as? String, "voluptatem")
        XCTAssertEqual(migratedAttribute.value(forKey: "value") as? String, "veritatis")

        // The "attributes" relationship should have been migrated too
        let migratedVariation = try XCTUnwrap(targetContext.allObjects(entityName: "ProductVariation").first)
        let migratedVariationAttributes = migratedVariation.mutableOrderedSetValue(forKey: "attributes")
        XCTAssertEqual(migratedVariationAttributes.count, 1)
        XCTAssertEqual(migratedVariationAttributes.firstObject as? NSManagedObject, migratedAttribute)

        // The migrated attribute can be accessed using the newly renamed `GenericAttribute` class.
        let genericAttribute = try XCTUnwrap(targetContext.firstObject(ofType: GenericAttribute.self))
        XCTAssertEqual(genericAttribute.id, 9_753_134)
        XCTAssertEqual(genericAttribute.key, "voluptatem")
        XCTAssertEqual(genericAttribute.value, "veritatis")
    }

    func test_migrating_from_32_to_33_sets_new_Product_attribute_date_to_dateCreated() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 32")
        let sourceContext = sourceContainer.viewContext

        let product = insertProduct(to: sourceContext, forModel: 32)
        let dateCreated = Date(timeIntervalSince1970: 1603250786)
        product.setValue(dateCreated, forKey: "dateCreated")

        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "Product"), 1)

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 33")

        // Then
        let targetContext = targetContainer.viewContext

        XCTAssertEqual(try targetContext.count(entityName: "Product"), 1)

        let migratedProduct = try XCTUnwrap(targetContext.first(entityName: "Product"))
        XCTAssertEqual(migratedProduct.value(forKey: "date") as? Date, dateCreated)
        XCTAssertEqual(migratedProduct.value(forKey: "dateCreated") as? Date, dateCreated)
    }

    func test_migrating_from_34_to_35_enables_creating_new_OrderItemAttribute_and_adding_to_OrderItem_attributes_relationship() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 34")
        let sourceContext = sourceContainer.viewContext

        let order = insertOrder(to: sourceContext)
        let orderItem = insertOrderItem(to: sourceContext)
        orderItem.setValue(order, forKey: "order")

        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "Order"), 1)
        XCTAssertEqual(try sourceContext.count(entityName: "OrderItem"), 1)

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 35")

        // Then
        let targetContext = targetContainer.viewContext

        XCTAssertEqual(try targetContext.count(entityName: "Order"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "OrderItem"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "OrderItemAttribute"), 0)

        let migratedOrderItem = try XCTUnwrap(targetContext.first(entityName: "OrderItem"))

        // Creates an `OrderItemAttribute` and adds it to `OrderItem`.
        let orderItemAttribute = insertOrderItemAttribute(to: targetContext)
        migratedOrderItem.setValue(NSOrderedSet(array: [orderItemAttribute]), forKey: "attributes")
        try targetContext.save()

        XCTAssertEqual(try targetContext.count(entityName: "OrderItemAttribute"), 1)
        XCTAssertEqual(migratedOrderItem.value(forKey: "attributes") as? NSOrderedSet, NSOrderedSet(array: [orderItemAttribute]))
    }

    func test_migrating_from_35_to_36_mantains_values_for_transformable_properties() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 35")
        let sourceContext = sourceContainer.viewContext

        let product = insertProduct(to: sourceContext, forModel: 35)
        product.setValue([1, 2, 3], forKey: "crossSellIDs")
        product.setValue([4, 5, 6], forKey: "groupedProducts")
        product.setValue([7, 8, 9], forKey: "relatedIDs")
        product.setValue([10, 11, 12], forKey: "upsellIDs")
        product.setValue([13, 14, 15], forKey: "variations")

        try sourceContext.save()

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 36")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedProduct = try XCTUnwrap(targetContext.first(entityName: "Product"))

        XCTAssertEqual(try targetContext.count(entityName: "Product"), 1)
        XCTAssertEqual(migratedProduct.value(forKey: "crossSellIDs") as? [Int64], [1, 2, 3])
        XCTAssertEqual(migratedProduct.value(forKey: "groupedProducts") as? [Int64], [4, 5, 6])
        XCTAssertEqual(migratedProduct.value(forKey: "relatedIDs") as? [Int64], [7, 8, 9])
        XCTAssertEqual(migratedProduct.value(forKey: "upsellIDs") as? [Int64], [10, 11, 12])
        XCTAssertEqual(migratedProduct.value(forKey: "variations") as? [Int64], [13, 14, 15])
    }

    func test_migrating_from_36_to_37_creates_new_paymentMethodID_property_on_order_with_nil_value() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 36")
        let sourceContext = sourceContainer.viewContext

        let order = insertOrder(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(order.entity.attributesByName["paymentMethodID"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 37")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedOrder = try XCTUnwrap(targetContext.first(entityName: "Order"))

        XCTAssertNotNil(migratedOrder.entity.attributesByName["paymentMethodID"])
        XCTAssertNil(migratedOrder.value(forKey: "paymentMethodID"))
    }

    func test_migrating_from_37_to_38_enables_creating_new_shipping_labels_entities() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 37")
        let sourceContext = sourceContainer.viewContext

        _ = insertOrder(to: sourceContainer.viewContext)
        try sourceContext.save()

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 38")

        // Then
        let targetContext = targetContainer.viewContext

        XCTAssertEqual(try targetContext.count(entityName: "Order"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "ShippingLabel"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "ShippingLabelAddress"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "ShippingLabelRefund"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "ShippingLabelSettings"), 0)

        let order = try XCTUnwrap(targetContext.first(entityName: "Order"))

        // Creates a `ShippingLabel` with all relationships.
        let originAddress = insertShippingLabelAddress(to: targetContext)
        let destinationAddress = insertShippingLabelAddress(to: targetContext)
        let shippingLabelRefund = insertShippingLabelRefund(to: targetContext)
        let shippingLabel = insertShippingLabel(to: targetContext)
        shippingLabel.setValue(originAddress, forKey: "originAddress")
        shippingLabel.setValue(destinationAddress, forKey: "destinationAddress")
        shippingLabel.setValue(shippingLabelRefund, forKey: "refund")
        shippingLabel.setValue(order, forKey: "order")

        // Creates a `ShippingLabelSettings`.
        let shippingLabelSettings = insertShippingLabelSettings(to: targetContext)
        shippingLabelSettings.setValue(order, forKey: "order")

        XCTAssertNoThrow(try targetContext.save())

        XCTAssertEqual(try targetContext.count(entityName: "Order"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "ShippingLabel"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "ShippingLabelAddress"), 2)
        XCTAssertEqual(try targetContext.count(entityName: "ShippingLabelRefund"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "ShippingLabelSettings"), 1)

        let savedOrder = try XCTUnwrap(targetContext.first(entityName: "Order"))
        XCTAssertEqual(savedOrder.value(forKey: "shippingLabels") as? Set<NSManagedObject>, [shippingLabel])
        XCTAssertEqual(savedOrder.value(forKey: "shippingLabelSettings") as? NSManagedObject, shippingLabelSettings)
    }

    func test_migrating_from_38_to_39_creates_new_shipping_lines_relationship_on_refund() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 38")
        let sourceContext = sourceContainer.viewContext

        let order = insertRefund(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(order.entity.relationshipsByName["shippingLines"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 39")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedRefund = try XCTUnwrap(targetContext.first(entityName: "Refund"))

        XCTAssertNotNil(migratedRefund.entity.relationshipsByName["shippingLines"])
        XCTAssertEqual(migratedRefund.value(forKey: "supportShippingRefunds") as? Bool, false)
    }

    func test_migrating_from_39_to_40_deletes_ProductAttribute_objects() throws {
        // Arrange
        let sourceContainer = try startPersistentContainer("Model 39")
        let sourceContext = sourceContainer.viewContext

        insertAccount(to: sourceContext)
        let product = insertProduct(to: sourceContext, forModel: 39)
        let productAttribute = insertProductAttribute(to: sourceContext)
        product.mutableSetValue(forKey: "attributes").add(productAttribute)

        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "Account"), 1)
        XCTAssertEqual(try sourceContext.count(entityName: "Product"), 1)
        XCTAssertEqual(try sourceContext.count(entityName: "ProductAttribute"), 1)

        // Action
        let targetContainer = try migrate(sourceContainer, to: "Model 40")
        let targetContext = targetContainer.viewContext

        // Assert
        XCTAssertEqual(try targetContext.count(entityName: "Account"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "Product"), 1)
        // Product attributes should be deleted.
        XCTAssertEqual(try targetContext.count(entityName: "ProductAttribute"), 0)

        // The Product.attributes inverse relationship should be gone too.
        let migratedProduct = try XCTUnwrap(targetContext.first(entityName: "Product"))
        XCTAssertEqual(migratedProduct.mutableSetValue(forKey: "attributes").count, 0)

        // We should still be able to add new attributes.
        let anotherAttribute = insertProductAttribute(to: targetContext)
        migratedProduct.mutableSetValue(forKey: "attributes").add(anotherAttribute)
        XCTAssertNoThrow(try targetContext.save())
    }

    func test_migrating_from_40_to_41_allow_use_to_create_ProductAttribute_terms() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 40")
        let sourceContext = sourceContainer.viewContext

        insertProductAttribute(to: sourceContext)
        try sourceContext.save()

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 41")

        // Then
        let targetContext = targetContainer.viewContext
        // Confidence-check
        XCTAssertEqual(try targetContext.count(entityName: "ProductAttribute"), 1)

        // Test we can add a term to a migrated `ProductAttribute`.
        let migratedAttribute = try XCTUnwrap(targetContext.first(entityName: "ProductAttribute"))
        let term = insertProductAttributeTerm(to: targetContext)
        migratedAttribute.mutableSetValue(forKey: "terms").add(term)

        XCTAssertNoThrow(try targetContext.save())
        // The ProductAttribute.attribute inverse relationship should be updated.
        XCTAssertEqual(term.value(forKey: "attribute") as? NSManagedObject, migratedAttribute)
    }

    func test_migrating_from_41_to_42_allow_use_to_create_Order_feeLines() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 41")
        let sourceContext = sourceContainer.viewContext

        insertOrder(to: sourceContext)
        try sourceContext.save()

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 42")

        // Then
        let targetContext = targetContainer.viewContext
        // Confidence-check
        XCTAssertEqual(try targetContext.count(entityName: "Order"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "OrderFeeLine"), 0)

        // Test we can add a fee to a migrated `Order`.
        let migratedOrder = try XCTUnwrap(targetContext.first(entityName: "Order"))
        let fee = insertOrderFeeLine(to: targetContext)
        migratedOrder.mutableSetValue(forKey: "fees").add(fee)

        XCTAssertNoThrow(try targetContext.save())

        // Confidence-check
        XCTAssertEqual(try targetContext.count(entityName: "OrderFeeLine"), 1)

        // The relationship between Order and OrderFeeLine should be updated.
        XCTAssertEqual(migratedOrder.value(forKey: "fees") as? Set<NSManagedObject>, [fee])

        // The OrderFeeLine.order inverse relationship should be updated.
        XCTAssertEqual(fee.value(forKey: "order") as? NSManagedObject, migratedOrder)
    }

    func test_migrating_from_42_to_43_deletes_SiteVisitStats_and_TopEarnerStats_objects_and_requires_siteID_for_new_objects() throws {
        // Arrange
        let sourceContainer = try startPersistentContainer("Model 42")
        let sourceContext = sourceContainer.viewContext

        insertSiteVisitStats(to: sourceContext)
        insertTopEarnerStats(to: sourceContext)

        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "SiteVisitStats"), 1)
        XCTAssertEqual(try sourceContext.count(entityName: "TopEarnerStats"), 1)

        // Action
        let targetContainer = try migrate(sourceContainer, to: "Model 43")
        let targetContext = targetContainer.viewContext

        // Assert
        // Pre-existing `SiteVisitStats` and `TopEarnerStats` objects should be deleted since model version 43 starts requiring a `siteID`.
        XCTAssertEqual(try targetContext.count(entityName: "SiteVisitStats"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "TopEarnerStats"), 0)

        // We should be able to add a new `SiteVisitStats` and `TopEarnerStats` with `siteID`.
        let siteVisitStats = insertSiteVisitStats(to: targetContext)
        siteVisitStats.setValue(66, forKey: "siteID")
        let topEarnerStats = insertTopEarnerStats(to: targetContext)
        topEarnerStats.setValue(66, forKey: "siteID")
        XCTAssertNoThrow(try targetContext.save())
    }

    func test_migrating_from_43_to_44_migrates_SiteVisitStats_with_empty_timeRange() throws {
        // Arrange
        let sourceContainer = try startPersistentContainer("Model 43")
        let sourceContext = sourceContainer.viewContext

        insertSiteVisitStats(to: sourceContext)

        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "SiteVisitStats"), 1)

        // Action
        let targetContainer = try migrate(sourceContainer, to: "Model 44")
        let targetContext = targetContainer.viewContext

        // Assert
        XCTAssertEqual(try targetContext.count(entityName: "SiteVisitStats"), 1)

        let migratedSiteVisitStats = try XCTUnwrap(targetContext.first(entityName: "SiteVisitStats"))
        XCTAssertEqual(migratedSiteVisitStats.value(forKey: "timeRange") as? String, "")

        // We should be able to set `SiteVisitStats`'s `timeRange` to a different value.
        migratedSiteVisitStats.setValue("today", forKey: "timeRange")
        XCTAssertNoThrow(try targetContext.save())
    }

    func test_migrating_from_44_to_45_migrates_AccountSettings_with_empty_firstName_and_lastName() throws {
        // Arrange
        let sourceContainer = try startPersistentContainer("Model 44")
        let sourceContext = sourceContainer.viewContext

        insertAccountSettingsWithoutFirstNameAndLastName(to: sourceContext)

        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "AccountSettings"), 1)

        // Action
        let targetContainer = try migrate(sourceContainer, to: "Model 45")
        let targetContext = targetContainer.viewContext

        // Assert
        XCTAssertEqual(try targetContext.count(entityName: "AccountSettings"), 1)

        let migratedSiteVisitStats = try XCTUnwrap(targetContext.first(entityName: "AccountSettings"))
        XCTAssertNil(migratedSiteVisitStats.value(forKey: "firstName") as? String)
        XCTAssertNil(migratedSiteVisitStats.value(forKey: "lastName") as? String)

        // We should be able to set `AccountSetttings`'s `firstName` and `lastName` to a different value.
        migratedSiteVisitStats.setValue("Mario", forKey: "firstName")
        migratedSiteVisitStats.setValue("Rossi", forKey: "lastName")
        XCTAssertNoThrow(try targetContext.save())
    }

    func test_migrating_from_45_to_46_migrates_ProductVariation_stockQuantity_from_Int64_to_Decimal() throws {
        // Arrange
        let sourceContainer = try startPersistentContainer("Model 45")
        let sourceContext = sourceContainer.viewContext

        let productVariation = insertProductVariation(to: sourceContext)
        productVariation.setValue(10, forKey: "stockQuantity")

        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "ProductVariation"), 1)
        XCTAssertEqual(productVariation.entity.attributesByName["stockQuantity"]?.attributeType, .integer64AttributeType)

        // Action
        let targetContainer = try migrate(sourceContainer, to: "Model 46")
        let targetContext = targetContainer.viewContext

        // Assert
        XCTAssertEqual(try targetContext.count(entityName: "ProductVariation"), 1)

        // Make sure stock quantity value is migrated as Decimal attribute type
        let migratedVariation = try XCTUnwrap(targetContext.first(entityName: "ProductVariation"))
        XCTAssertEqual(migratedVariation.entity.attributesByName["stockQuantity"]?.attributeType, .decimalAttributeType)
    }

    func test_migrating_from_49_to_50_enables_creating_new_sitePlugin_entities() throws {
        // Arrange
        let sourceContainer = try startPersistentContainer("Model 49")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Action
        let targetContainer = try migrate(sourceContainer, to: "Model 50")
        let targetContext = targetContainer.viewContext

        // Assert
        XCTAssertEqual(try targetContext.count(entityName: "SitePlugin"), 0)

        let plugin = insertSitePlugin(to: targetContext)
        let insertedPlugin = try XCTUnwrap(targetContext.firstObject(ofType: SitePlugin.self))

        XCTAssertEqual(try targetContext.count(entityName: "SitePlugin"), 1)
        XCTAssertEqual(insertedPlugin, plugin)
    }

    func test_migrating_from_50_to_51_removes_OrderCount_entities() throws {
        // Arrange
        let sourceContainer = try startPersistentContainer("Model 50")
        let sourceContext = sourceContainer.viewContext

        let orderCount = insertOrderCount(to: sourceContext)
        let orderCountItem1 = insertOrderCountItem(slug: "processing", to: sourceContext)
        let orderCountItem2 = insertOrderCountItem(slug: "completed", to: sourceContext)
        orderCount.mutableSetValue(forKey: "items").add(orderCountItem1)
        orderCount.mutableSetValue(forKey: "items").add(orderCountItem2)
        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "OrderCount"), 1)
        XCTAssertEqual(try sourceContext.count(entityName: "OrderCountItem"), 2)

        let sourceEntitiesNames = sourceContainer.managedObjectModel.entitiesByName.keys
        XCTAssertTrue(sourceEntitiesNames.contains("OrderCount"))
        XCTAssertTrue(sourceEntitiesNames.contains("OrderCountItem"))

        // Action
        let targetContainer = try migrate(sourceContainer, to: "Model 51")
        let targetEntitiesNames = targetContainer.managedObjectModel.entitiesByName.keys

        // Assert
        XCTAssertFalse(targetEntitiesNames.contains("OrderCount"))
        XCTAssertFalse(targetEntitiesNames.contains("OrderCountItem"))
    }

    func test_migrating_from_51_to_52_enables_creating_new_paymentGatewayAccount_entities() throws {
        // Arrange
        let sourceContainer = try startPersistentContainer("Model 51")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Action
        let targetContainer = try migrate(sourceContainer, to: "Model 52")
        let targetContext = targetContainer.viewContext

        // Assert
        XCTAssertEqual(try targetContext.count(entityName: "PaymentGatewayAccount"), 0)

        let paymentGatewayAccount = insertPaymentGatewayAccount(to: targetContext)
        let insertedAccount = try XCTUnwrap(targetContext.firstObject(ofType: PaymentGatewayAccount.self))

        XCTAssertEqual(try targetContext.count(entityName: "PaymentGatewayAccount"), 1)
        XCTAssertEqual(insertedAccount, paymentGatewayAccount)
    }

    func test_migrating_from_52_to_53_enables_creating_new_StateOfACountry_and_adding_to_Country_attributes_relationship() throws {
        // Arrange
        let sourceContainer = try startPersistentContainer("Model 52")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Action
        let targetContainer = try migrate(sourceContainer, to: "Model 53")
        let targetContext = targetContainer.viewContext

        // Assert
        XCTAssertEqual(try targetContext.count(entityName: "Country"), 0)

        let stateOfCountry1 = insertStateOfACountry(code: "DZ-01", name: "Adrar", to: targetContext)
        let stateOfCountry2 = insertStateOfACountry(code: "DZ-02", name: "Chlef", to: targetContext)
        let country = insertCountry(to: targetContext)
        country.mutableSetValue(forKey: "states").add(stateOfCountry1)
        country.mutableSetValue(forKey: "states").add(stateOfCountry2)
        let insertedCountry = try XCTUnwrap(targetContext.firstObject(ofType: Country.self))

        XCTAssertEqual(try targetContext.count(entityName: "Country"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "StateOfACountry"), 2)
        XCTAssertEqual(insertedCountry, country)
    }

    func test_migrating_from_53_to_54_enables_creating_new_systemPlugin_entities() throws {
        // Arrange
        let sourceContainer = try startPersistentContainer("Model 53")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Action
        let targetContainer = try migrate(sourceContainer, to: "Model 54")
        let targetContext = targetContainer.viewContext

        // Assert
        XCTAssertEqual(try targetContext.count(entityName: "SystemPlugin"), 0)

        let systemPlugin = insertSystemPlugin(to: targetContext)
        let insertedSystemPlugin = try XCTUnwrap(targetContext.firstObject(ofType: SystemPlugin.self))

        XCTAssertEqual(try targetContext.count(entityName: "SystemPlugin"), 1)
        XCTAssertEqual(insertedSystemPlugin, systemPlugin)
    }

    func test_migrating_from_54_to_55_adds_new_attribute_commercialInvoiceURL_with_nil_value() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 54")
        let sourceContext = sourceContainer.viewContext

        let shippingLabel = insertShippingLabel(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(shippingLabel.entity.attributesByName["commercialInvoiceURL"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 55")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedShippingLabel = try XCTUnwrap(targetContext.first(entityName: "ShippingLabel"))

        XCTAssertNotNil(migratedShippingLabel.entity.attributesByName["commercialInvoiceURL"])
        XCTAssertNil(migratedShippingLabel.value(forKey: "commercialInvoiceURL"))
    }

    func test_migrating_from_55_to_56_adds_new_systemplugin_attribute_active_with_true_value() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 55")
        let sourceContext = sourceContainer.viewContext

        let systemPlugin = insertSystemPlugin(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(systemPlugin.entity.attributesByName["active"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 56")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedSystemPlugin = try XCTUnwrap(targetContext.first(entityName: "SystemPlugin"))

        XCTAssertNotNil(migratedSystemPlugin.entity.attributesByName["active"])
        XCTAssertEqual(migratedSystemPlugin.value(forKey: "active") as? Bool, true)
    }

    func test_migrating_from_56_to_57_adds_new_PaymentGatewayAccount_attributes() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 56")
        let sourceContext = sourceContainer.viewContext

        let paymentGatewayAccount = insertPaymentGatewayAccount(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(paymentGatewayAccount.entity.attributesByName["isLive"])
        XCTAssertNil(paymentGatewayAccount.entity.attributesByName["isInTestMode"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 57")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedPaymentGatewayAccount = try XCTUnwrap(targetContext.first(entityName: "PaymentGatewayAccount"))

        XCTAssertNotNil(migratedPaymentGatewayAccount.entity.attributesByName["isLive"])
        XCTAssertEqual(migratedPaymentGatewayAccount.value(forKey: "isLive") as? Bool, true)
        XCTAssertNotNil(migratedPaymentGatewayAccount.entity.attributesByName["isInTestMode"])
        XCTAssertEqual(migratedPaymentGatewayAccount.value(forKey: "isInTestMode") as? Bool, false)
    }

    func test_migrating_from_57_to_58_adds_new_site_jetpack_attributes() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 57")
        let sourceContext = sourceContainer.viewContext

        let site = insertSite(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(site.entity.attributesByName["isJetpackConnected"])
        XCTAssertNil(site.entity.attributesByName["isJetpackThePluginInstalled"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 58")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedSite = try XCTUnwrap(targetContext.first(entityName: "Site"))

        let isJetpackConnected = try XCTUnwrap(migratedSite.value(forKey: "isJetpackConnected") as? Bool)
        XCTAssertFalse(isJetpackConnected)
        let isJetpackThePluginInstalled = try XCTUnwrap(migratedSite.value(forKey: "isJetpackThePluginInstalled") as? Bool)
        XCTAssertFalse(isJetpackThePluginInstalled)
    }

    func test_migrating_from_58_to_59_adds_site_jetpack_connection_active_plugins_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 58")
        let sourceContext = sourceContainer.viewContext

        let site = insertSite(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(site.entity.attributesByName["jetpackConnectionActivePlugins"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 59")
        let targetContext = targetContainer.viewContext

        let migratedSite = try XCTUnwrap(targetContext.first(entityName: "Site"))
        let defaultJetpackConnectionActivePlugins = migratedSite.value(forKey: "jetpackConnectionActivePlugins")

        let plugins = ["jetpack", "woocommerce-payments"]
        migratedSite.setValue(plugins, forKey: "jetpackConnectionActivePlugins")

        // Then
        // Default value is nil.
        XCTAssertNil(defaultJetpackConnectionActivePlugins)

        let jetpackConnectionActivePlugins = try XCTUnwrap(migratedSite.value(forKey: "jetpackConnectionActivePlugins") as? [String])
        XCTAssertEqual(jetpackConnectionActivePlugins, plugins)
    }

    func test_migrating_from_58_to_59_adds_adminURL_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 58")
        let sourceContext = sourceContainer.viewContext

        let site = insertSite(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(site.entity.attributesByName["adminURL"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 59")
        let targetContext = targetContainer.viewContext

        let migratedSite = try XCTUnwrap(targetContext.first(entityName: "Site"))
        let defaultAdminURL = migratedSite.value(forKey: "adminURL")

        let adminURL = "https://test.blog/wp-admin"
        migratedSite.setValue(adminURL, forKey: "adminURL")

        // Then
        // Default value is nil.
        XCTAssertNil(defaultAdminURL)

        let newAdminURL = try XCTUnwrap(migratedSite.value(forKey: "adminURL") as? String)
        XCTAssertEqual(newAdminURL, adminURL)
    }

    func test_migrating_from_59_to_60_adds_order_orderKey_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 59")
        let sourceContext = sourceContainer.viewContext

        let site = insertOrder(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(site.entity.attributesByName["orderKey"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 60")
        let targetContext = targetContainer.viewContext

        let migratedOrder = try XCTUnwrap(targetContext.first(entityName: "Order"))
        let defaultOrderKey = migratedOrder.value(forKey: "orderKey")

        let orderValue = "frtgyh87654567"
        migratedOrder.setValue(orderValue, forKey: "orderKey")

        // Then
        // Default value is empty
        XCTAssertEqual(defaultOrderKey as? String, "")

        let newOrderKey = try XCTUnwrap(migratedOrder.value(forKey: "orderKey") as? String)
        XCTAssertEqual(newOrderKey, orderValue)
    }

    func test_migrating_from_59_to_60_enables_creating_new_Coupon() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 59")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 60")

        // Then
        let targetContext = targetContainer.viewContext
        XCTAssertEqual(try targetContext.count(entityName: "Coupon"), 0)

        // Creates an `Coupon`
        let coupon = insertCoupon(to: targetContext)

        XCTAssertEqual(try targetContext.count(entityName: "Coupon"), 1)
        XCTAssertEqual(try XCTUnwrap(targetContext.firstObject(ofType: Coupon.self)), coupon)
    }

    func test_migrating_from_60_to_61_adds_tax_lines_as_a_property_to_order() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 60")
        let sourceContext = sourceContainer.viewContext

        let order = insertOrder(to: sourceContext)
        try sourceContext.save()

        // `taxes` should not be present before migration
        XCTAssertNil(order.entity.relationshipsByName["taxes"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 61")

        // Then
        let targetContext = targetContainer.viewContext
        // Confidence-check
        XCTAssertEqual(try targetContext.count(entityName: "Order"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "OrderTaxLine"), 0)

        let migratedOrder = try XCTUnwrap(targetContext.first(entityName: "Order"))

        // `taxes` should be present in `migratedOrder`
        XCTAssertNotNil(migratedOrder.entity.relationshipsByName["taxes"])

        // Test adding tax to a migrated `Order`.
        let tax = insertOrderTaxLine(to: targetContext)
        migratedOrder.mutableSetValue(forKey: "taxes").add(tax)

        XCTAssertNoThrow(try targetContext.save())

        // Confidence-check
        XCTAssertEqual(try targetContext.count(entityName: "OrderTaxLine"), 1)

        // The relationship between Order and OrderTaxLine should be updated.
        XCTAssertEqual(migratedOrder.value(forKey: "taxes") as? Set<NSManagedObject>, [tax])

        // The OrderTaxLine.order inverse relationship should be updated.
        XCTAssertEqual(tax.value(forKey: "order") as? NSManagedObject, migratedOrder)
    }

    func test_migrating_from_61_to_62_adds_new_attribute_searchResults_to_coupon() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 61")
        let sourceContext = sourceContainer.viewContext

        // `searchResults` should not be present before the migration
        let coupon = insertCoupon(to: sourceContext)
        XCTAssertNil(coupon.entity.relationshipsByName["searchResults"])
        XCTAssertNoThrow(try sourceContext.save())

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 62")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedCoupon = try XCTUnwrap(targetContext.first(entityName: "Coupon"))
        XCTAssertNotNil(migratedCoupon.entity.relationshipsByName["searchResults"])

        // Creates a `CouponSearchResult`
        let searchResult = insertCouponSearchResult(to: targetContext)
        migratedCoupon.mutableSetValue(forKey: "searchResults").add(searchResult)

        XCTAssertNoThrow(try targetContext.save())
        XCTAssertEqual(try XCTUnwrap(targetContext.firstObject(ofType: CouponSearchResult.self)), searchResult)

        // The relationship between Coupon and CouponSearchResult should be updated.
        XCTAssertEqual(migratedCoupon.value(forKey: "searchResults") as? Set<NSManagedObject>, [searchResult])

        // The CouponSearchResult.coupons inverse relationship should be updated.
        XCTAssertEqual(searchResult.value(forKey: "coupons") as? Set<NSManagedObject>, [migratedCoupon])
    }

    func test_migrating_from_62_to_63_adds_new_attribute_chargeID_to_order() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 62")
        let sourceContext = sourceContainer.viewContext

        let site = insertOrder(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(site.entity.attributesByName["chargeID"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 63")
        let targetContext = targetContainer.viewContext

        let migratedOrder = try XCTUnwrap(targetContext.first(entityName: "Order"))
        let defaultChargeID = migratedOrder.value(forKey: "chargeID")

        let orderValue = "ch_3KMtak2EdyGr1FMV02G9Qqq1"
        migratedOrder.setValue(orderValue, forKey: "chargeID")

        // Then
        // Default value is nil
        XCTAssertNil(defaultChargeID)

        let newOrderKey = try XCTUnwrap(migratedOrder.value(forKey: "chargeID") as? String)
        XCTAssertEqual(newOrderKey, orderValue)
    }

    func test_migrating_from_63_to_64_enables_creating_new_InboxNote() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 63")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 64")

        // Then
        let targetContext = targetContainer.viewContext
        XCTAssertEqual(try targetContext.count(entityName: "InboxNote"), 0)

        // Creates a `InboxNote`
        let inboxNote = insertInboxNote(to: targetContext)

        // Creates an `InboxAction` and adds it to `InboxNote`.
        let inboxAction = insertInboxAction(to: targetContext)
        inboxNote.setValue(NSSet(array: [inboxAction]), forKey: "actions")
        try targetContext.save()

        XCTAssertNotNil(inboxNote.entity.relationshipsByName["actions"])
        XCTAssertEqual(try targetContext.count(entityName: "InboxNote"), 1)
        XCTAssertEqual(try XCTUnwrap(targetContext.firstObject(ofType: InboxNote.self)), inboxNote)
    }

    func test_migrating_from_64_to_65_enables_creating_new_WCPayCharge_withCardPaymentDetails() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 64")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 65")

        // Then
        let targetContext = targetContainer.viewContext
        XCTAssertEqual(try targetContext.count(entityName: "WCPayCardPaymentDetails"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "WCPayCharge"), 0)

        // Creates nested cardPresent objects
        let payment = insertWCPayCardPaymentDetails(to: targetContext)

        // Creates an `WCPayCharge`
        let wcPayCharge = insertWCPayCharge(to: targetContext)
        wcPayCharge.setValue(payment, forKey: "cardDetails")


        XCTAssertEqual(try targetContext.count(entityName: "WCPayCardPaymentDetails"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "WCPayCharge"), 1)
        XCTAssertEqual(try XCTUnwrap(targetContext.firstObject(ofType: WCPayCharge.self)), wcPayCharge)
        XCTAssertEqual(wcPayCharge.value(forKey: "cardDetails") as? WCPayCardPaymentDetails, payment)
    }

    func test_migrating_from_64_to_65_enables_creating_new_WCPayCharge_withCardPresentPaymentDetails() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 64")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 65")

        // Then
        let targetContext = targetContainer.viewContext
        XCTAssertEqual(try targetContext.count(entityName: "WCPayCardPresentReceiptDetails"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "WCPayCardPresentPaymentDetails"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "WCPayCharge"), 0)

        // Creates nested cardPresent objects
        let receipt = insertWCPayCardPresentReceiptDetails(to: targetContext)
        let payment = insertWCPayCardPresentPaymentDetails(to: targetContext)

        payment.setValue(receipt, forKey: "receipt")

        // Creates an `WCPayCharge`
        let wcPayCharge = insertWCPayCharge(to: targetContext)
        wcPayCharge.setValue(payment, forKey: "cardPresentDetails")


        XCTAssertEqual(try targetContext.count(entityName: "WCPayCardPresentReceiptDetails"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "WCPayCardPresentPaymentDetails"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "WCPayCharge"), 1)
        XCTAssertEqual(try XCTUnwrap(targetContext.firstObject(ofType: WCPayCharge.self)), wcPayCharge)
        XCTAssertEqual(wcPayCharge.value(forKey: "cardPresentDetails") as? WCPayCardPresentPaymentDetails, payment)
        XCTAssertEqual(payment.value(forKey: "receipt") as? WCPayCardPresentReceiptDetails, receipt)
    }

    func test_migrating_from_65_to_66_makes_items_ordered_in_order() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 65")
        let sourceContext = sourceContainer.viewContext

        let _ = insertOrder(to: sourceContext)

        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "Order"), 1)
        XCTAssertEqual(try sourceContext.count(entityName: "OrderItem"), 0)

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 66")

        // Then
        let targetContext = targetContainer.viewContext

        XCTAssertEqual(try targetContext.count(entityName: "Order"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "OrderItem"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "OrderItemAttribute"), 0)

        let migratedOrder = try XCTUnwrap(targetContext.first(entityName: "Order"))

        // Creates an `OrderItem` and adds it to `Order`.
        let orderItem1 = insertOrderItem(itemID: 1, to: targetContext)
        let orderItem2 = insertOrderItem(itemID: 2, to: targetContext)
        let orderItem3 = insertOrderItem(itemID: 3, to: targetContext)
        migratedOrder.setValue(NSOrderedSet(array: [orderItem1, orderItem3, orderItem2]), forKey: "items")
        try targetContext.save()

        XCTAssertEqual(try targetContext.count(entityName: "OrderItem"), 3)
        XCTAssertEqual(migratedOrder.value(forKey: "items") as? NSOrderedSet, NSOrderedSet(array: [orderItem1, orderItem3, orderItem2]))
    }

    func test_migrating_from_66_to_67_adds_paymentURL_field() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 66")
        let sourceContext = sourceContainer.viewContext

        let _ = insertOrder(to: sourceContext)

        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "Order"), 1)

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 67")

        // Then
        let targetContext = targetContainer.viewContext

        XCTAssertEqual(try targetContext.count(entityName: "Order"), 1)
        let migratedOrder = try XCTUnwrap(targetContext.first(entityName: "Order"))

        // Checks for nil URL value.
        XCTAssertNil(migratedOrder.value(forKey: "paymentURL"))

        // Set a random URL
        let url = NSURL(string: "www.automattic.com") ?? NSURL()
        migratedOrder.setValue(url, forKey: "paymentURL")

        // Check URL is correctly set.
        XCTAssertEqual(migratedOrder.value(forKey: "paymentURL") as? NSURL, url)
    }

    func test_migrating_from_67_to_68_enables_creating_new_Coupon_with_some_fields_optional() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 67")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 68")

        // Then
        let targetContext = targetContainer.viewContext
        XCTAssertEqual(try targetContext.count(entityName: "Coupon"), 0)

        // Creates an `Coupon`
        let coupon = insertCoupon(to: targetContext,
                                  limitUsageToXItems: nil,
                                  usageLimitPerUser: nil,
                                  usageLimit: nil)

        XCTAssertEqual(try targetContext.count(entityName: "Coupon"), 1)

        let couponFetched = try XCTUnwrap(targetContext.firstObject(ofType: Coupon.self))
        XCTAssertNil(couponFetched.value(forKey: "limitUsageToXItems"))
        XCTAssertNil(couponFetched.value(forKey: "usageLimitPerUser"))
        XCTAssertNil(couponFetched.value(forKey: "usageLimit"))
        XCTAssertEqual(try XCTUnwrap(targetContext.firstObject(ofType: Coupon.self)), coupon)
    }

    func test_migrating_from_68_to_69_adds_new_order_properties() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 68")
        let sourceContext = sourceContainer.viewContext

        let _ = insertOrder(to: sourceContext)

        try sourceContext.save()

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 69")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "Order"), 1)
        let migratedOrder = try XCTUnwrap(targetContext.first(entityName: "Order"))

        // Checks for default values.
        XCTAssertEqual(migratedOrder.value(forKey: "isEditable") as? Bool, false)
        XCTAssertEqual(migratedOrder.value(forKey: "needsPayment") as? Bool, false)
        XCTAssertEqual(migratedOrder.value(forKey: "needsProcessing") as? Bool, false)
    }

    func test_migrating_from_69_to_70_adds_refundedItemID_property_to_OrderItemRefund() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 69")
        let sourceContext = sourceContainer.viewContext

        let orderItemRefund = insertOrderItemRefund(to: sourceContext)

        // Confidence check:
        // The `itemID` property already exists on Model 69, but the `refundedItemID` does not
        XCTAssertNotNil(orderItemRefund.entity.attributesByName["itemID"])
        XCTAssertNil(orderItemRefund.entity.attributesByName["refundedItemID"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 70")
        let targetContext = targetContainer.viewContext
        let migratedOrderItemRefund = insertOrderItemRefund(to: targetContext)

        // Confirms the `refundedItemID` property now exists on Model 70
        XCTAssertNotNil(migratedOrderItemRefund.entity.attributesByName["refundedItemID"])
    }

    func test_migrating_from_70_to_71_adds_custom_fields_property_to_order() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 70")
        let sourceContext = sourceContainer.viewContext

        let order = insertOrder(to: sourceContext)
        try sourceContext.save()

        // `customFields` should not be present before migration
        XCTAssertNil(order.entity.relationshipsByName["customFields"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 71")
        let targetContext = targetContainer.viewContext

        // Confidence check
        XCTAssertEqual(try targetContext.count(entityName: "Order"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "OrderMetaData"), 0)

        let migratedOrder = try XCTUnwrap(targetContext.first(entityName: "Order"))

        // `customFields` should be present in `migratedOrder`
        XCTAssertNotNil(migratedOrder.entity.relationshipsByName["customFields"])

        // Test adding custom fields to a migrated `Order`.
        let customField = insertOrderMetaData(to: targetContext)
        migratedOrder.mutableSetValue(forKey: "customFields").add(customField)

        XCTAssertNoThrow(try targetContext.save())

        // Confidence check
        XCTAssertEqual(try targetContext.count(entityName: "OrderMetaData"), 1)

        // The relationship between Order and OrderMetaData should be updated.
        XCTAssertEqual(migratedOrder.value(forKey: "customFields") as? Set<NSManagedObject>, [customField])

        // The OrderMetaData.order inverse relationship should be updated.
        XCTAssertEqual(customField.value(forKey: "order") as? NSManagedObject, migratedOrder)
    }

    func test_migrating_from_71_to_72_adds_instructions_attribute_to_PaymentGateway() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 71")
        let sourceContext = sourceContainer.viewContext

        let paymentGateway = insertPaymentGateway(to: sourceContext)
        try sourceContext.save()

        // `instructions` should not be present before migration
        XCTAssertNil(paymentGateway.entity.relationshipsByName["instructions"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 72")
        let targetContext = targetContainer.viewContext

        // Confidence check
        XCTAssertEqual(try targetContext.count(entityName: "PaymentGateway"), 1)

        let migratedPaymentGateway = try XCTUnwrap(targetContext.first(entityName: "PaymentGateway"))

        // The instructions should be nil after migration: it's an optional field.
        XCTAssertNil(migratedPaymentGateway.value(forKey: "instructions"))

        // Set a test instructions
        migratedPaymentGateway.setValue("payment gateway instructions", forKey: "instructions")

        // Check instructions are correctly set.
        assertEqual("payment gateway instructions", migratedPaymentGateway.value(forKey: "instructions") as? String)
    }

    func test_migrating_from_72_to_73_adds_filterKey_attribute_to_ProductSearchResults() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 72")
        let sourceContext = sourceContainer.viewContext

        let productSearchResults = insertProductSearchResults(to: sourceContext)
        try sourceContext.save()

        // `filterKey` should not be present before migration.
        XCTAssertNil(productSearchResults.entity.attributesByName["filterKey"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 73")
        let targetContext = targetContainer.viewContext

        XCTAssertEqual(try targetContext.count(entityName: "ProductSearchResults"), 1)
        let migratedProductSearchResults = try XCTUnwrap(targetContext.first(entityName: "ProductSearchResults"))

        // Checks for nil URL value.
        XCTAssertNil(migratedProductSearchResults.value(forKey: "filterKey"))

        // Sets a random `filterKey`.
        migratedProductSearchResults.setValue("sku", forKey: "filterKey")
        targetContext.saveIfNeeded()

        // Check `filterKey` is correctly set.
        XCTAssertEqual(migratedProductSearchResults.value(forKey: "filterKey") as? String, "sku")
    }

    func test_migrating_from_73_to_74_adds_Customer_and_CustomerSearchResult_entities() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 73")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. These entities should not exist in Model 73
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "Customer", in: sourceContext))
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "CustomerSearchResult", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 74")

        // Then
        let targetContext = targetContainer.viewContext

        // These entities should exist in Model 74
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "Customer", in: targetContext))
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "CustomerSearchResult", in: targetContext))
        XCTAssertEqual(try targetContext.count(entityName: "Customer"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "CustomerSearchResult"), 0)

        // Insert a new Customer
        let customer = insertCustomer(to: targetContext, forModel: 74)
        XCTAssertEqual(try targetContext.count(entityName: "Customer"), 1)
        XCTAssertEqual(customer.value(forKey: "customerID") as? Int64, 1)

        // Insert a new CustomerSearchResult
        let customerSearchResult = targetContext.insert(
            entityName: "CustomerSearchResult",
            properties: ["customerID": 1]
        )
        XCTAssertEqual(try targetContext.count(entityName: "CustomerSearchResult"), 1)
        XCTAssertEqual(customer.value(forKey: "customerID") as? Int64, 1)

        // Check all attributes
        XCTAssertEqual(customerSearchResult.value(forKey: "customerID") as? Int64, 1)
        XCTAssertNotNil(customer.entity.attributesByName["email"])
        XCTAssertNotNil(customer.entity.attributesByName["firstName"])
        XCTAssertNotNil(customer.entity.attributesByName["lastName"])
        XCTAssertNotNil(customer.entity.attributesByName["billingAddress1"])
        XCTAssertNotNil(customer.entity.attributesByName["billingAddress2"])
        XCTAssertNotNil(customer.entity.attributesByName["billingCity"])
        XCTAssertNotNil(customer.entity.attributesByName["billingCompany"])
        XCTAssertNotNil(customer.entity.attributesByName["billingCountry"])
        XCTAssertNotNil(customer.entity.attributesByName["billingEmail"])
        XCTAssertNotNil(customer.entity.attributesByName["billingFirstName"])
        XCTAssertNotNil(customer.entity.attributesByName["billingLastName"])
        XCTAssertNotNil(customer.entity.attributesByName["billingPhone"])
        XCTAssertNotNil(customer.entity.attributesByName["billingPostcode"])
        XCTAssertNotNil(customer.entity.attributesByName["billingState"])
        XCTAssertNotNil(customer.entity.attributesByName["shippingAddress1"])
        XCTAssertNotNil(customer.entity.attributesByName["shippingAddress2"])
        XCTAssertNotNil(customer.entity.attributesByName["shippingCity"])
        XCTAssertNotNil(customer.entity.attributesByName["shippingCompany"])
        XCTAssertNotNil(customer.entity.attributesByName["shippingCountry"])
        XCTAssertNotNil(customer.entity.attributesByName["shippingEmail"])
        XCTAssertNotNil(customer.entity.attributesByName["shippingFirstName"])
        XCTAssertNotNil(customer.entity.attributesByName["shippingLastName"])
        XCTAssertNotNil(customer.entity.attributesByName["shippingPhone"])
        XCTAssertNotNil(customer.entity.attributesByName["shippingPostcode"])
        XCTAssertNotNil(customer.entity.attributesByName["shippingState"])
    }

    func test_migrating_from_74_to_75_adds_siteID_and_keyword_attributes_to_Customer_and_CustomerSearchResult() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 74")
        let sourceContext = sourceContainer.viewContext

        let customer = insertCustomer(to: sourceContext, forModel: 74)
        let customerSearchResult = sourceContext.insert(
            entityName: "CustomerSearchResult",
            properties: ["customerID": 1]
        )
        try sourceContext.save()

        // Confidence Check: siteID or keyword attributes should not exist in Model 74 for those entities
        XCTAssertNil(customer.entity.attributesByName["siteID"])
        XCTAssertNil(customerSearchResult.entity.attributesByName["siteID"])
        XCTAssertNil(customerSearchResult.entity.attributesByName["keyword"])
        // Confidence Check: These entities should exist in Model 74:
        XCTAssertEqual(try sourceContext.count(entityName: "Customer"), 1)
        XCTAssertEqual(try sourceContext.count(entityName: "CustomerSearchResult"), 1)

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 75")
        let targetContext = targetContainer.viewContext

        // Then
        // After migration, we're deleting the entities and regenerating them due to heavyweight migration
        // in WooCommerceModelV74toV75, as the new ones have siteID
        XCTAssertEqual(try targetContext.count(entityName: "Customer"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "CustomerSearchResult"), 0)
        // Inserting new objects after the migration to confirm the new attributes are correct
        let newCustomer = insertCustomer(to: targetContext, forModel: 75)
        let newCustomerSearchResult = targetContext.insert(
            entityName: "CustomerSearchResult",
            properties: [
                "siteID": 1,
                "keyword": ""
            ]
        )
        try targetContext.save()

        // Check for Customer and CustomerSearchResult attributes after migration
        XCTAssertNotNil(newCustomer.entity.attributesByName["siteID"])
        XCTAssertNotNil(newCustomer.entity.attributesByName["customerID"])
        XCTAssertEqual(newCustomer.value(forKey: "siteID") as? Int64, 1)
        XCTAssertEqual(newCustomer.value(forKey: "customerID") as? Int64, 1)

        // Check for CustomerSearchResult attributes after migration
        XCTAssertNotNil(newCustomerSearchResult.entity.attributesByName["siteID"])
        XCTAssertNotNil(newCustomerSearchResult.entity.attributesByName["keyword"])
        XCTAssertEqual(newCustomerSearchResult.value(forKey: "siteID") as? Int64, 1)
        XCTAssertEqual(newCustomerSearchResult.value(forKey: "keyword") as? String, "")
    }

    func test_migrating_from_75_to_76_adds_loginURL_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 75")
        let sourceContext = sourceContainer.viewContext

        let site = insertSite(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(site.entity.attributesByName["loginURL"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 76")
        let targetContext = targetContainer.viewContext

        let migratedSite = try XCTUnwrap(targetContext.first(entityName: "Site"))
        let defaultLoginURL = migratedSite.value(forKey: "loginURL")

        let loginURL = "https://test.blog/wp-login.php"
        migratedSite.setValue(loginURL, forKey: "loginURL")

        // Then
        // Default value is nil.
        XCTAssertNil(defaultLoginURL)

        let newLoginURL = try XCTUnwrap(migratedSite.value(forKey: "loginURL") as? String)
        XCTAssertEqual(newLoginURL, loginURL)
    }

    func test_migrating_from_76_to_77_adds_frameNonce_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 76")
        let sourceContext = sourceContainer.viewContext

        let site = insertSite(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(site.entity.attributesByName["frameNonce"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 77")
        let targetContext = targetContainer.viewContext

        let migratedSite = try XCTUnwrap(targetContext.first(entityName: "Site"))
        let defaultFrameNonce = migratedSite.value(forKey: "frameNonce")

        let frameNonce = "e7bfd785f0"
        migratedSite.setValue(frameNonce, forKey: "frameNonce")

        // Then
        // Default value is nil.
        XCTAssertNil(defaultFrameNonce)

        let newFrameNonce = try XCTUnwrap(migratedSite.value(forKey: "frameNonce") as? String)
        XCTAssertEqual(newFrameNonce, frameNonce)
    }

    func test_migrating_from_77_to_78_adds_averageOrderValue_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 77")
        let sourceContext = sourceContainer.viewContext

        let orderStatsV4Totals = insertOrderStatsTotals(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(orderStatsV4Totals.entity.attributesByName["averageOrderValue"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 78")
        let targetContext = targetContainer.viewContext

        let migratedOrderStatsV4Totals = try XCTUnwrap(targetContext.first(entityName: "OrderStatsV4Totals"))
        let defaultAverageOrderValue = try XCTUnwrap(migratedOrderStatsV4Totals.value(forKey: "averageOrderValue") as? Double)

        let averageOrderValue = 123.45
        migratedOrderStatsV4Totals.setValue(averageOrderValue, forKey: "averageOrderValue")

        // Then
        // Default value is 0.
        XCTAssertEqual(defaultAverageOrderValue, 0)

        let newAverageOrderValue = try XCTUnwrap(migratedOrderStatsV4Totals.value(forKey: "averageOrderValue") as? Double)
        XCTAssertEqual(newAverageOrderValue, averageOrderValue)
    }

    func test_migrating_from_78_to_79_adds_views_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 78")
        let sourceContext = sourceContainer.viewContext

        let siteVisitStatsItem = insertSiteVisitStatsItem(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(siteVisitStatsItem.entity.attributesByName["views"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 79")
        let targetContext = targetContainer.viewContext

        let migratedSiteVisitStatsItem = try XCTUnwrap(targetContext.first(entityName: "SiteVisitStatsItem"))
        let defaultViewsCount = try XCTUnwrap(migratedSiteVisitStatsItem.value(forKey: "views") as? Int)

        let viewsCount = 12
        migratedSiteVisitStatsItem.setValue(viewsCount, forKey: "views")

        // Then
        // Default value is 0.
        XCTAssertEqual(defaultViewsCount, 0)

        let newViewsCount = try XCTUnwrap(migratedSiteVisitStatsItem.value(forKey: "views") as? Int)
        XCTAssertEqual(newViewsCount, viewsCount)
    }

    func test_migrating_from_79_to_80_enables_creating_new_SiteSummaryStats_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 79")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. This entity should not exist in Model 79
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "SiteSummaryStats", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 80")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "SiteSummaryStats"), 0)

        let summaryStats = insertSiteSummaryStats(to: targetContext)
        let insertedStats = try XCTUnwrap(targetContext.firstObject(ofType: SiteSummaryStats.self))

        XCTAssertEqual(try targetContext.count(entityName: "SiteSummaryStats"), 1)
        XCTAssertEqual(insertedStats, summaryStats)
    }

    func test_migrating_from_80_to_81_adds_new_product_bundle_attributes_and_ProductBundleItem_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 80")
        let sourceContext = sourceContainer.viewContext

        let product = insertProduct(to: sourceContext, forModel: 80)
        try sourceContext.save()

        // Confidence Checks. This entity and attributes should not exist in Model 80.
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "ProductBundleItem", in: sourceContext))
        XCTAssertNil(product.entity.attributesByName["bundleStockQuantity"])
        XCTAssertNil(product.entity.attributesByName["bundleStockStatus"])
        XCTAssertNil(product.entity.relationshipsByName["bundledItems"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 81")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "Product"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "ProductBundleItem"), 0)

        let migratedProduct = try XCTUnwrap(targetContext.firstObject(ofType: Product.self))

        // Migrated product has expected (nil/empty) bundle attributes.
        XCTAssertNil(migratedProduct.value(forKey: "bundleStockQuantity"))
        XCTAssertNil(migratedProduct.value(forKey: "bundleStockStatus"))
        XCTAssertEqual(migratedProduct.mutableOrderedSetValue(forKey: "bundledItems").count, 0)

        // Insert a new ProductBundleItem and add it to Product, along with new Product attributes.
        let bundledItem = insertProductBundleItem(to: targetContext)
        let bundleStockQuantity: Int64 = 0
        let bundleStockStatus = "insufficientStock"
        migratedProduct.setValue(bundleStockQuantity, forKey: "bundleStockQuantity")
        migratedProduct.setValue(bundleStockStatus, forKey: "bundleStockStatus")
        migratedProduct.setValue(NSOrderedSet(array: [bundledItem]), forKey: "bundledItems")
        try targetContext.save()

        // ProductBundleItem entity and attributes exist, including relationship with Product.
        XCTAssertEqual(try targetContext.count(entityName: "ProductBundleItem"), 1)
        XCTAssertNotNil(bundledItem.value(forKey: "bundledItemID"))
        XCTAssertNotNil(bundledItem.value(forKey: "menuOrder"))
        XCTAssertNotNil(bundledItem.value(forKey: "productID"))
        XCTAssertNotNil(bundledItem.value(forKey: "stockStatus"))
        XCTAssertNotNil(bundledItem.value(forKey: "title"))
        XCTAssertEqual(bundledItem.value(forKey: "product") as? NSManagedObject, migratedProduct)

        // Product attributes exist, including relationship with ProductBundleItem.
        XCTAssertEqual(migratedProduct.value(forKey: "bundleStockQuantity") as? Int64, bundleStockQuantity)
        XCTAssertEqual(migratedProduct.value(forKey: "bundleStockStatus") as? String, bundleStockStatus)
        XCTAssertEqual(migratedProduct.value(forKey: "bundledItems") as? NSOrderedSet, NSOrderedSet(array: [bundledItem]))
    }

    func test_migrating_from_81_to_82_enables_creating_new_ProductCompositeComponent_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 81")
        let sourceContext = sourceContainer.viewContext

        let product = insertProduct(to: sourceContext, forModel: 81)
        try sourceContext.save()

        // Confidence Checks. This entity and relationship should not exist in Model 81.
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "ProductCompositeComponent", in: sourceContext))
        XCTAssertNil(product.entity.relationshipsByName["compositeComponents"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 82")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "Product"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "ProductCompositeComponent"), 0)

        // Migrated product has expected empty components attribute.
        let migratedProduct = try XCTUnwrap(targetContext.firstObject(ofType: Product.self))
        XCTAssertEqual(migratedProduct.mutableOrderedSetValue(forKey: "compositeComponents").count, 0)

        // Insert a new ProductCompositeComponent and add it to Product.
        let component = insertCompositeComponent(to: targetContext)
        migratedProduct.setValue(NSOrderedSet(array: [component]), forKey: "compositeComponents")
        try targetContext.save()

        // ProductCompositeComponent entity and attributes exist, including relationship with Product.
        XCTAssertEqual(try targetContext.count(entityName: "ProductCompositeComponent"), 1)
        XCTAssertNotNil(component.value(forKey: "componentID"))
        XCTAssertNotNil(component.value(forKey: "title"))
        XCTAssertNotNil(component.value(forKey: "imageURL"))
        XCTAssertNotNil(component.value(forKey: "optionType"))
        XCTAssertNotNil(component.value(forKey: "optionIDs"))
        XCTAssertNotNil(component.value(forKey: "componentDescription"))
        XCTAssertNotNil(component.value(forKey: "defaultOptionID"))
        XCTAssertEqual(component.value(forKey: "product") as? NSManagedObject, migratedProduct)

        // Product components attribute exists.
        XCTAssertEqual(migratedProduct.value(forKey: "compositeComponents") as? NSOrderedSet, NSOrderedSet(array: [component]))
    }

    func test_migrating_from_82_to_83_enables_creating_new_ProductSubscription_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 82")
        let sourceContext = sourceContainer.viewContext

        let product = insertProduct(to: sourceContext, forModel: 82)
        let productVariation = insertProductVariation(to: sourceContext)
        try sourceContext.save()

        // Confidence Checks. This entity and relationship should not exist in Model 82.
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "ProductSubscription", in: sourceContext))
        XCTAssertNil(product.entity.relationshipsByName["subscription"])
        XCTAssertNil(productVariation.entity.relationshipsByName["subscription"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 83")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "Product"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "ProductVariation"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "ProductSubscription"), 0)

        // Migrated product has expected empty subscription attribute.
        let migratedProduct = try XCTUnwrap(targetContext.firstObject(ofType: Product.self))
        XCTAssertNil(migratedProduct.value(forKey: "subscription"))

        // Migrated product variation has expected empty subscription attribute.
        let migratedProductVariation = try XCTUnwrap(targetContext.firstObject(ofType: ProductVariation.self))
        XCTAssertNil(migratedProductVariation.value(forKey: "subscription"))

        // Insert a new ProductSubscription and add it to Product and ProductVariation.
        let subscription = insertProductSubscription(to: targetContext)
        migratedProduct.setValue(subscription, forKey: "subscription")
        migratedProductVariation.setValue(subscription, forKey: "subscription")
        try targetContext.save()

        // ProductSubscription entity and attributes exist, including relationship with Product and ProductVariation.
        XCTAssertEqual(try targetContext.count(entityName: "ProductSubscription"), 1)
        XCTAssertNotNil(subscription.value(forKey: "length"))
        XCTAssertNotNil(subscription.value(forKey: "period"))
        XCTAssertNotNil(subscription.value(forKey: "periodInterval"))
        XCTAssertNotNil(subscription.value(forKey: "price"))
        XCTAssertNotNil(subscription.value(forKey: "signUpFee"))
        XCTAssertNotNil(subscription.value(forKey: "trialLength"))
        XCTAssertNotNil(subscription.value(forKey: "trialPeriod"))
        XCTAssertEqual(subscription.value(forKey: "product") as? NSManagedObject, migratedProduct)
        XCTAssertEqual(subscription.value(forKey: "productVariation") as? NSManagedObject, migratedProductVariation)

        // Product and ProductVariation subscription relationship exists.
        XCTAssertEqual(migratedProduct.value(forKey: "subscription") as? NSManagedObject, subscription)
        XCTAssertEqual(migratedProductVariation.value(forKey: "subscription") as? NSManagedObject, subscription)
    }

    func test_migrating_from_83_to_84_adds_isPublic_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 83")
        let sourceContext = sourceContainer.viewContext

        let site = insertSite(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(site.entity.attributesByName["isPublic"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 84")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedSite = try XCTUnwrap(targetContext.first(entityName: "Site"))

        let isPublic = try XCTUnwrap(migratedSite.value(forKey: "isPublic") as? Bool)
        XCTAssertFalse(isPublic)
    }

    func test_migrating_from_84_to_85_adds_renewalSubscriptionID_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 84")
        let sourceContext = sourceContainer.viewContext

        let order = insertOrder(to: sourceContainer.viewContext)
        try sourceContext.save()

        XCTAssertNil(order.entity.attributesByName["renewalSubscriptionID"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 85")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedOrder = try XCTUnwrap(targetContext.first(entityName: "Order"))

        // Migrated order has expected default nil renewalSubscriptionID attribute.
        XCTAssertNil(migratedOrder.value(forKey: "renewalSubscriptionID"))

        // Set value for renewalSubscriptionID attribute.
        let renewalSubscriptionID = "123"
        migratedOrder.setValue(renewalSubscriptionID, forKey: "renewalSubscriptionID")
        try targetContext.save()

        // New value is set correctly for renewalSubscriptionID attribute.
        let newRenewalSubscriptionID = try XCTUnwrap(migratedOrder.value(forKey: "renewalSubscriptionID") as? String)
        XCTAssertEqual(newRenewalSubscriptionID, renewalSubscriptionID)
    }

    func test_migrating_from_84_to_85_enables_creating_new_OrderGiftCard_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 84")
        let sourceContext = sourceContainer.viewContext

        let order = insertOrder(to: sourceContainer.viewContext)
        try sourceContext.save()

        // Confidence Checks. This entity and relationship should not exist in Model 84.
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "OrderGiftCard", in: sourceContext))
        XCTAssertNil(order.entity.relationshipsByName["appliedGiftCards"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 85")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "Order"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "OrderGiftCard"), 0)

        // Migrated order has expected empty appliedGiftCards attribute.
        let migratedOrder = try XCTUnwrap(targetContext.firstObject(ofType: Order.self))
        XCTAssertEqual(migratedOrder.mutableSetValue(forKey: "appliedGiftCards").count, 0)

        // Insert a new OrderGiftCard and add it to Order.
        let giftCard = insertOrderGiftCard(to: targetContext)
        migratedOrder.setValue(NSSet(array: [giftCard]), forKey: "appliedGiftCards")
        try targetContext.save()

        // OrderGiftCard entity and attributes exist, including relationship with Order.
        XCTAssertEqual(try targetContext.count(entityName: "OrderGiftCard"), 1)
        XCTAssertNotNil(giftCard.value(forKey: "giftCardID"))
        XCTAssertNotNil(giftCard.value(forKey: "code"))
        XCTAssertNotNil(giftCard.value(forKey: "amount"))
        XCTAssertEqual(giftCard.value(forKey: "order") as? NSManagedObject, migratedOrder)

        // Order appliedGiftCards relationship exists.
        XCTAssertEqual(migratedOrder.value(forKey: "appliedGiftCards") as? NSSet, NSSet(array: [giftCard]))
    }

    func test_migrating_from_85_to_86_adds_min_max_quantities_attributes() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 85")
        let sourceContext = sourceContainer.viewContext

        let product = insertProduct(to: sourceContainer.viewContext, forModel: 85)
        let variation = insertProductVariation(to: sourceContainer.viewContext)
        try sourceContext.save()

        // Attributes do not exist in Model 85.
        XCTAssertNil(product.entity.attributesByName["minAllowedQuantity"])
        XCTAssertNil(product.entity.attributesByName["maxAllowedQuantity"])
        XCTAssertNil(product.entity.attributesByName["groupOfQuantity"])
        XCTAssertNil(product.entity.attributesByName["combineVariationQuantities"])
        XCTAssertNil(variation.entity.attributesByName["minAllowedQuantity"])
        XCTAssertNil(variation.entity.attributesByName["maxAllowedQuantity"])
        XCTAssertNil(variation.entity.attributesByName["groupOfQuantity"])
        XCTAssertNil(variation.entity.attributesByName["overrideProductQuantities"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 86")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedProduct = try XCTUnwrap(targetContext.first(entityName: "Product"))
        let migratedVariation = try XCTUnwrap(targetContext.first(entityName: "ProductVariation"))

        // Migrated product and variation have expected default nil attributes.
        XCTAssertNil(migratedProduct.value(forKey: "minAllowedQuantity"))
        XCTAssertNil(migratedProduct.value(forKey: "maxAllowedQuantity"))
        XCTAssertNil(migratedProduct.value(forKey: "groupOfQuantity"))
        XCTAssertNil(migratedProduct.value(forKey: "combineVariationQuantities"))
        XCTAssertNil(migratedVariation.value(forKey: "minAllowedQuantity"))
        XCTAssertNil(migratedVariation.value(forKey: "maxAllowedQuantity"))
        XCTAssertNil(migratedVariation.value(forKey: "groupOfQuantity"))
        XCTAssertNil(migratedVariation.value(forKey: "overrideProductQuantities"))

        // Set values for new attributes.
        let quantityValue = "2"
        migratedProduct.setValue(quantityValue, forKey: "minAllowedQuantity")
        migratedProduct.setValue(quantityValue, forKey: "maxAllowedQuantity")
        migratedProduct.setValue(quantityValue, forKey: "groupOfQuantity")
        migratedProduct.setValue(true, forKey: "combineVariationQuantities")
        migratedVariation.setValue(quantityValue, forKey: "minAllowedQuantity")
        migratedVariation.setValue(quantityValue, forKey: "maxAllowedQuantity")
        migratedVariation.setValue(quantityValue, forKey: "groupOfQuantity")
        migratedVariation.setValue(true, forKey: "overrideProductQuantities")
        try targetContext.save()

        // New values are set correctly for attributes.
        XCTAssertEqual(try XCTUnwrap(migratedProduct.value(forKey: "minAllowedQuantity") as? String), quantityValue)
        XCTAssertEqual(try XCTUnwrap(migratedProduct.value(forKey: "maxAllowedQuantity") as? String), quantityValue)
        XCTAssertEqual(try XCTUnwrap(migratedProduct.value(forKey: "groupOfQuantity") as? String), quantityValue)
        XCTAssertTrue(try XCTUnwrap(migratedProduct.value(forKey: "combineVariationQuantities") as? Bool))
        XCTAssertEqual(try XCTUnwrap(migratedVariation.value(forKey: "minAllowedQuantity") as? String), quantityValue)
        XCTAssertEqual(try XCTUnwrap(migratedVariation.value(forKey: "maxAllowedQuantity") as? String), quantityValue)
        XCTAssertEqual(try XCTUnwrap(migratedVariation.value(forKey: "groupOfQuantity") as? String), quantityValue)
        XCTAssertTrue(try XCTUnwrap(migratedVariation.value(forKey: "overrideProductQuantities") as? Bool))
    }

    func test_migrating_from_86_to_87_adds_OrderItem_parent_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 86")
        let sourceContext = sourceContainer.viewContext

        let order = insertOrder(to: sourceContext)
        let orderItem = insertOrderItem(to: sourceContext)
        orderItem.setValue(order, forKey: "order")
        try sourceContext.save()

        // Attribute does not exist in Model 86.
        XCTAssertEqual(try sourceContext.count(entityName: "Order"), 1)
        XCTAssertEqual(try sourceContext.count(entityName: "OrderItem"), 1)
        XCTAssertNil(orderItem.entity.attributesByName["parent"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 87")

        // Then
        let targetContext = targetContainer.viewContext
        _ = try XCTUnwrap(targetContext.first(entityName: "Order"))
        let migratedOrderItem = try XCTUnwrap(targetContext.first(entityName: "OrderItem"))

        // Migrated order item has expected default nil parent attribute.
        XCTAssertNil(migratedOrderItem.value(forKey: "parent"))

        // Set value for new parent attribute.
        let parentID: Int64 = 1234
        migratedOrderItem.setValue(parentID, forKey: "parent")
        try targetContext.save()

        // New value is set correctly for parent attribute.
        XCTAssertEqual(try XCTUnwrap(migratedOrderItem.value(forKey: "parent") as? Int64), parentID)
    }

    func test_migrating_from_87_to_88_updates_gift_card_amount_to_Double() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 87")
        let sourceContext = sourceContainer.viewContext

        let orderGiftCard = insertOrderGiftCard(to: sourceContext)
        orderGiftCard.setValue(1, forKey: "amount")
        try sourceContext.save()

        // Value for gift card amount is Int64.
        XCTAssertEqual(try sourceContext.count(entityName: "OrderGiftCard"), 1)
        XCTAssertEqual(try XCTUnwrap(orderGiftCard.value(forKey: "amount") as? Int64), 1)

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 88")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedOrderGiftCard = try XCTUnwrap(targetContext.first(entityName: "OrderGiftCard"))

        // Migrated value for gift card amount is Double.
        XCTAssertEqual(try XCTUnwrap(migratedOrderGiftCard.value(forKey: "amount") as? Double), 1.0)
    }

    func test_migrating_from_88_to_89_removes_unused_OrderStatsV4Totals_attributes() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 88")
        let sourceContext = sourceContainer.viewContext

        _ = insertOrderStatsTotals(to: sourceContext)
        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "OrderStatsV4Totals"), 1)

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 89")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedOrderStatsV4Totals = try XCTUnwrap(targetContext.first(entityName: "OrderStatsV4Totals"))

        // Check OrderStatsV4Totals entity still exists.
        XCTAssertEqual(try targetContext.count(entityName: "OrderStatsV4Totals"), 1)

        // Check expected attributes still exist.
        XCTAssertNotNil(migratedOrderStatsV4Totals.entity.attributesByName["averageOrderValue"])
        XCTAssertNotNil(migratedOrderStatsV4Totals.entity.attributesByName["grossRevenue"])
        XCTAssertNotNil(migratedOrderStatsV4Totals.entity.attributesByName["netRevenue"])
        XCTAssertNotNil(migratedOrderStatsV4Totals.entity.attributesByName["totalItemsSold"])
        XCTAssertNotNil(migratedOrderStatsV4Totals.entity.attributesByName["totalOrders"])

        // Check removed attributes do not exist.
        XCTAssertNil(migratedOrderStatsV4Totals.entity.attributesByName["couponDiscount"])
        XCTAssertNil(migratedOrderStatsV4Totals.entity.attributesByName["refunds"])
        XCTAssertNil(migratedOrderStatsV4Totals.entity.attributesByName["shipping"])
        XCTAssertNil(migratedOrderStatsV4Totals.entity.attributesByName["taxes"])
        XCTAssertNil(migratedOrderStatsV4Totals.entity.attributesByName["totalCoupons"])
        XCTAssertNil(migratedOrderStatsV4Totals.entity.attributesByName["totalProducts"])
    }

    func test_migrating_from_89_to_90_adds_new_isSiteOwner_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 89")
        let sourceContext = sourceContainer.viewContext

        let site = insertSite(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(site.entity.attributesByName["isSiteOwner"], "Precondition. Property does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 90")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedSiteEntity = try XCTUnwrap(targetContext.first(entityName: "Site"))

        let isSiteOwner = try XCTUnwrap(migratedSiteEntity.value(forKey: "isSiteOwner") as? Bool)
        XCTAssertFalse(isSiteOwner, "Confirm expected property exists, and is false.")
    }

    func test_migrating_from_90_to_91_adds_new_isAdmin_and_canBlaze_attributes() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 90")
        let sourceContext = sourceContainer.viewContext

        let site = insertSite(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(site.entity.attributesByName["isAdmin"], "Precondition. Property does not exist.")
        XCTAssertNil(site.entity.attributesByName["canBlaze"], "Precondition. Property does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 91")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedSiteEntity = try XCTUnwrap(targetContext.first(entityName: "Site"))

        let isAdmin = try XCTUnwrap(migratedSiteEntity.value(forKey: "isAdmin") as? Bool)
        XCTAssertFalse(isAdmin, "Confirm expected property exists, and is false by default.")

        let canBlaze = try XCTUnwrap(migratedSiteEntity.value(forKey: "canBlaze") as? Bool)
        XCTAssertFalse(canBlaze, "Confirm expected property exists, and is false by default.")
    }

    func test_migrating_from_91_to_92_adds_new_wasEcommerceTrial_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 91")
        let sourceContext = sourceContainer.viewContext

        let site = insertSite(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(site.entity.attributesByName["wasEcommerceTrial"], "Precondition. Property does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 92")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedSiteEntity = try XCTUnwrap(targetContext.first(entityName: "Site"))

        let wasEcommerceTrial = try XCTUnwrap(migratedSiteEntity.value(forKey: "wasEcommerceTrial") as? Bool)
        XCTAssertFalse(wasEcommerceTrial, "Confirm expected property exists, and is false by default.")
    }

    func test_migrating_from_92_to_93_adds_new_username_attribute_in_customer() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 92")
        let sourceContext = sourceContainer.viewContext

        let customer = insertCustomer(to: sourceContext, forModel: 92)
        try sourceContext.save()

        XCTAssertNil(customer.entity.attributesByName["username"], "Precondition. Property does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 93")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedCustomerEntity = try XCTUnwrap(targetContext.first(entityName: "Customer"))

        XCTAssertNotNil(migratedCustomerEntity.entity.attributesByName["username"], "Confirm expected property exists")
    }

    func test_migrating_from_93_to_94_enables_creating_new_OrderItemProductAddOn_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 93")
        let sourceContext = sourceContainer.viewContext

        let order = insertOrder(to: sourceContext)
        let orderItem = insertOrderItem(to: sourceContext)
        orderItem.setValue(order, forKey: "order")
        try sourceContext.save()

        // Confidence Checks. This entity and relationship should not exist in Model 93.
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "OrderItemProductAddOn", in: sourceContext))
        XCTAssertNil(orderItem.entity.relationshipsByName["addOns"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 94")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "OrderItem"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "OrderItemProductAddOn"), 0)

        // Migrated order item has empty add-ons.
        let migratedOrderItem = try XCTUnwrap(targetContext.firstObject(ofType: OrderItem.self))
        XCTAssertEqual(migratedOrderItem.value(forKey: "addOns") as? NSOrderedSet, [])

        // Insert a new OrderItemProductAddOn and add it to order item.
        let addOn = insertOrderItemProductAddOn(to: targetContext)
        addOn.setValue(migratedOrderItem, forKey: "orderItem")
        try targetContext.save()

        // OrderItemProductAddOn entity and attributes exist, including relationship with OrderItem.
        XCTAssertEqual(try targetContext.count(entityName: "OrderItemProductAddOn"), 1)
        XCTAssertEqual(addOn.value(forKey: "addOnID") as? NSNumber, .init(value: 645))
        XCTAssertEqual(addOn.value(forKey: "key") as? String, "Sugar level")
        XCTAssertEqual(addOn.value(forKey: "value") as? String, "Zero")
        XCTAssertEqual(addOn.value(forKey: "orderItem") as? NSManagedObject, migratedOrderItem)

        // OrderItem's addOns relationship exists.
        XCTAssertEqual(migratedOrderItem.value(forKey: "addOns") as? NSOrderedSet, [addOn])
    }

    func test_migrating_from_94_to_95_enables_creating_new_TaxRate_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 94")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. This entity should not exist in Model 94.
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "TaxRate", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 95")

        // Then
        let targetContext = targetContainer.viewContext
        XCTAssertEqual(try targetContext.count(entityName: "TaxRate"), 0)

        let taxRate = insertTaxRate(to: targetContext, forModel: 95)

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "TaxRate"), 1)
        XCTAssertEqual(taxRate.value(forKey: "id") as? Int, 123123)
        XCTAssertEqual(taxRate.value(forKey: "state") as? String, "FL")
        XCTAssertEqual(taxRate.value(forKey: "postcode") as? String, "1234")
        XCTAssertEqual(taxRate.value(forKey: "postcodes") as? [String], ["1234"])
        XCTAssertEqual(taxRate.value(forKey: "priority") as? Int, 1)
        XCTAssertEqual(taxRate.value(forKey: "name") as? String, "State Tax")
        XCTAssertEqual(taxRate.value(forKey: "order") as? Int, 1)
        XCTAssertEqual(taxRate.value(forKey: "taxRateClass") as? String, "standard")
        XCTAssertEqual(taxRate.value(forKey: "shipping") as? Bool, true)
        XCTAssertEqual(taxRate.value(forKey: "compound") as? Bool, true)
        XCTAssertEqual(taxRate.value(forKey: "city") as? String, "Miami")
        XCTAssertEqual(taxRate.value(forKey: "cities") as? [String], ["Miami"])
    }

    func test_migrating_from_95_to_96_adds_new_siteID_attribute_in_taxRate() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 95")
        let sourceContext = sourceContainer.viewContext

        let taxRate = insertTaxRate(to: sourceContext, forModel: 95)
        try sourceContext.save()

        XCTAssertNil(taxRate.entity.attributesByName["siteID"], "Precondition. Property does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 96")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedTaxRateEntity = try XCTUnwrap(targetContext.first(entityName: "TaxRate"))

        XCTAssertNotNil(migratedTaxRateEntity.entity.attributesByName["siteID"], "Confirm expected property exists")
    }

    func test_migrating_from_95_to_96_keeps_transformables_in_taxRate_after_changing_transformer() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 95")
        let sourceContext = sourceContainer.viewContext

        _ = insertTaxRate(to: sourceContext, forModel: 95)
        try sourceContext.save()

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 96")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedTaxRateEntity = try XCTUnwrap(targetContext.first(entityName: "TaxRate")) as? TaxRate

        XCTAssertEqual(migratedTaxRateEntity?.value(forKey: "postcodes") as? [String], ["1234"])
        XCTAssertEqual(migratedTaxRateEntity?.value(forKey: "cities") as? [String], ["Miami"])
    }

    func test_migrating_from_96_to_97_keeps_transformables_in_taxRate_after_changing_transformer() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 96")
        let sourceContext = sourceContainer.viewContext

        _ = insertTaxRate(to: sourceContext, forModel: 96)
        try sourceContext.save()

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 97")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedTaxRateEntity = try XCTUnwrap(targetContext.first(entityName: "TaxRate")) as? TaxRate

        XCTAssertEqual(migratedTaxRateEntity?.value(forKey: "postcodes") as? [String], ["1234"])
        XCTAssertEqual(migratedTaxRateEntity?.value(forKey: "cities") as? [String], ["Miami"])
    }

    func test_migrating_from_97_to_98_adds_new_isAIAssitantFeatureActive_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 97")
        let sourceContext = sourceContainer.viewContext

        let site = insertSite(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(site.entity.attributesByName["isAIAssitantFeatureActive"], "Precondition. Property does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 98")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedSiteEntity = try XCTUnwrap(targetContext.first(entityName: "Site"))

        let isAIAssitantFeatureActive = try XCTUnwrap(migratedSiteEntity.value(forKey: "isAIAssitantFeatureActive") as? Bool)
        XCTAssertFalse(isAIAssitantFeatureActive, "Confirm expected property exists, and is false by default.")
    }

    func test_migrating_from_97_to_98_adds_new_isSampleItem_attribute_to_product() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 97")
        let sourceContext = sourceContainer.viewContext

        let product = insertProduct(to: sourceContext, forModel: 97)
        try sourceContext.save()

        XCTAssertNil(product.entity.attributesByName["isSampleItem"], "Precondition. Property does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 98")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedProductEntity = try XCTUnwrap(targetContext.first(entityName: "Product"))

        let isSampleItem = try XCTUnwrap(migratedProductEntity.value(forKey: "isSampleItem") as? Bool)
        XCTAssertFalse(isSampleItem, "Confirm expected property exists, and is false by default.")
    }

    func test_migrating_from_98_to_99_adds_new_attributes_to_ProductBundleItem() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 98")
        let sourceContext = sourceContainer.viewContext

        let product = insertProduct(to: sourceContext, forModel: 98)

        // Inserts a new ProductBundleItem and add it to Product.
        let bundledItem = insertProductBundleItem(to: sourceContext)
        product.setValue(NSOrderedSet(array: [bundledItem]), forKey: "bundledItems")
        try sourceContext.save()

        XCTAssertNil(bundledItem.entity.attributesByName["minQuantity"], "Precondition. Property does not exist.")
        XCTAssertNil(bundledItem.entity.attributesByName["maxQuantity"], "Precondition. Property does not exist.")
        XCTAssertNil(bundledItem.entity.attributesByName["defaultQuantity"], "Precondition. Property does not exist.")
        XCTAssertNil(bundledItem.entity.attributesByName["isOptional"], "Precondition. Property does not exist.")
        XCTAssertNil(bundledItem.entity.attributesByName["overridesVariations"], "Precondition. Property does not exist.")
        XCTAssertNil(bundledItem.entity.attributesByName["overridesDefaultVariationAttributes"], "Precondition. Property does not exist.")
        XCTAssertNil(bundledItem.entity.attributesByName["allowedVariations"], "Precondition. Property does not exist.")
        XCTAssertNil(bundledItem.entity.relationshipsByName["defaultVariationAttributes"], "Precondition. Relationship does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 99")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedProduct = try XCTUnwrap(targetContext.first(entityName: "Product"))
        let migratedBundledItem = try XCTUnwrap(targetContext.first(entityName: "ProductBundleItem"))

        XCTAssertEqual(try targetContext.count(entityName: "Product"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "ProductBundleItem"), 1)

        // ProductBundleItem has the expected default values for the new attributes.
        XCTAssertEqual(migratedBundledItem.value(forKey: "minQuantity") as? Int64, 0)
        XCTAssertEqual(migratedBundledItem.value(forKey: "maxQuantity") as? Int64, 0)
        XCTAssertEqual(migratedBundledItem.value(forKey: "defaultQuantity") as? Int64, 0)
        XCTAssertEqual(migratedBundledItem.value(forKey: "isOptional") as? Bool, true)
        XCTAssertEqual(migratedBundledItem.value(forKey: "overridesVariations") as? Bool, false)
        XCTAssertEqual(migratedBundledItem.value(forKey: "overridesDefaultVariationAttributes") as? Bool, false)
        XCTAssertEqual(migratedBundledItem.value(forKey: "allowedVariations") as? [Int64], nil)
        XCTAssertEqual(migratedBundledItem.value(forKey: "defaultVariationAttributes") as? [GenericAttribute], nil)
        XCTAssertEqual(migratedBundledItem.value(forKey: "product") as? NSManagedObject, migratedProduct)

        // Product's relationship to ProductBundleItem exists.
        XCTAssertEqual(migratedProduct.value(forKey: "bundledItems") as? NSOrderedSet, NSOrderedSet(array: [migratedBundledItem]))
    }

    func test_migrating_from_99_to_100_adds_BlazeCampaign_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 99")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. `BlazeCampaign` should not exist in Model 73
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "BlazeCampaign", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 100")

        // Then
        let targetContext = targetContainer.viewContext

        // `BlazeCampaign` should exist in Model 100
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "BlazeCampaign", in: targetContext))
        XCTAssertEqual(try targetContext.count(entityName: "BlazeCampaign"), 0)

        // Insert a new BlazeCampaign
        let campaign = insertBlazeCampaign(to: targetContext, forModel: 100)
        XCTAssertEqual(try targetContext.count(entityName: "BlazeCampaign"), 1)

        // Check all attributes
        XCTAssertEqual(campaign.value(forKey: "campaignID") as? Int64, 1)
        XCTAssertEqual(campaign.value(forKey: "siteID") as? Int64, 1)
        XCTAssertEqual(campaign.value(forKey: "contentClickURL") as? String, "https://example.com/products/1")
        XCTAssertEqual(campaign.value(forKey: "contentImageURL") as? String, "https://example.com/products/1/thumbnail.png")
        XCTAssertEqual(campaign.value(forKey: "name") as? String, "Product")
        XCTAssertEqual(campaign.value(forKey: "rawStatus") as? String, "approved")
        XCTAssertEqual(campaign.value(forKey: "totalBudget") as? Double, 150)
        XCTAssertEqual(campaign.value(forKey: "totalClicks") as? Int64, 11)
        XCTAssertEqual(campaign.value(forKey: "totalImpressions") as? Int64, 33)
    }

    func test_migrating_from_100_to_101_adds_productID_to_BlazeCampaign() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 100")
        let sourceContext = sourceContainer.viewContext

        let campaign = insertBlazeCampaign(to: sourceContext, forModel: 100)

        try sourceContext.save()

        XCTAssertNil(campaign.entity.attributesByName["productID"], "Precondition. Property does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 101")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedCampaign = try XCTUnwrap(targetContext.first(entityName: "BlazeCampaign"))

        // BlazeCampaign has the expected default value for the new attribute.
        let productID = migratedCampaign.value(forKey: "productID") as? NSNumber
        XCTAssertNil(productID, "Confirm expected property exists and is nil by default.")

        // For model 101, saved BlazeCampaign with specific product ID has the expected product ID value.
        let newCampaign = insertBlazeCampaign(to: targetContext, forModel: 101)
        try targetContext.save()
        XCTAssertEqual(newCampaign.value(forKey: "productID") as? NSNumber, .init(value: 123))
    }

    func test_migrating_from_101_to_102_adds_bundleMinSize_and_bundleMaxSize_to_Product() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 101")
        let sourceContext = sourceContainer.viewContext

        let product = insertProduct(to: sourceContext, forModel: 101)

        try sourceContext.save()

        XCTAssertNil(product.entity.attributesByName["bundleMinSize"], "Precondition. Property does not exist.")
        XCTAssertNil(product.entity.attributesByName["bundleMaxSize"], "Precondition. Property does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 102")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedProduct = try XCTUnwrap(targetContext.first(entityName: "Product"))

        // The new properties are nil by default.
        XCTAssertNil(migratedProduct.value(forKey: "bundleMinSize") as? NSDecimalNumber, "Confirm expected property exists and is nil by default.")
        XCTAssertNil(migratedProduct.value(forKey: "bundleMaxSize") as? NSDecimalNumber, "Confirm expected property exists and is nil by default.")

        migratedProduct.setValue(2, forKey: "bundleMinSize")
        migratedProduct.setValue(6, forKey: "bundleMaxSize")
        try targetContext.save()
        XCTAssertEqual(migratedProduct.value(forKey: "bundleMinSize") as? NSDecimalNumber, 2)
        XCTAssertEqual(migratedProduct.value(forKey: "bundleMaxSize") as? NSDecimalNumber, 6)
    }

    func test_migrating_from_102_to_103_adds_new_oneTimeShipping_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 102")
        let sourceContext = sourceContainer.viewContext

        let productSubscription = insertProductSubscription(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(productSubscription.entity.attributesByName["oneTimeShipping"], "Precondition. Property does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 103")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedProductSubscriptionEntity = try XCTUnwrap(targetContext.first(entityName: "ProductSubscription"))

        let oneTimeShipping = try XCTUnwrap(migratedProductSubscriptionEntity.value(forKey: "oneTimeShipping") as? Bool)
        XCTAssertFalse(oneTimeShipping, "Confirm expected property exists, and is false by default.")
    }

    func test_migrating_from_102_to_103_adds_new_paymentSyncDate_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 102")
        let sourceContext = sourceContainer.viewContext

        let productSubscription = insertProductSubscription(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(productSubscription.entity.attributesByName["paymentSyncDate"], "Precondition. Property does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 103")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedProductSubscriptionEntity = try XCTUnwrap(targetContext.first(entityName: "ProductSubscription"))

        let paymentSyncDate = try XCTUnwrap(migratedProductSubscriptionEntity.value(forKey: "paymentSyncDate") as? String)
        XCTAssertEqual(paymentSyncDate, "", "Confirm expected property exists, and is empty by default.")

        // When
        migratedProductSubscriptionEntity.setValue("30", forKey: "paymentSyncDate")
        try targetContext.save()

        // Then
        XCTAssertEqual(migratedProductSubscriptionEntity.value(forKey: "paymentSyncDate") as? String, "30")
    }

    func test_migrating_from_102_to_103_adds_new_paymentSyncMonth_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 102")
        let sourceContext = sourceContainer.viewContext

        let productSubscription = insertProductSubscription(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(productSubscription.entity.attributesByName["paymentSyncMonth"], "Precondition. Property does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 103")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedProductSubscriptionEntity = try XCTUnwrap(targetContext.first(entityName: "ProductSubscription"))

        let paymentSyncMonth = try XCTUnwrap(migratedProductSubscriptionEntity.value(forKey: "paymentSyncMonth") as? String)
        XCTAssertEqual(paymentSyncMonth, "", "Confirm expected property exists, and is empty by default.")

        // When
        migratedProductSubscriptionEntity.setValue("02", forKey: "paymentSyncMonth")
        try targetContext.save()

        // Then
        XCTAssertEqual(migratedProductSubscriptionEntity.value(forKey: "paymentSyncMonth") as? String, "02")
    }

    func test_migrating_from_103_to_104_adds_new_pricedIndividually_attribute() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 103")
        let sourceContext = sourceContainer.viewContext

        let productBundleItem = insertProductBundleItem(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(productBundleItem.entity.attributesByName["pricedIndividually"], "Precondition. Property does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 104")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedProductBundleItemEntity = try XCTUnwrap(targetContext.first(entityName: "ProductBundleItem"))

        // The new attribute is false by default.
        let pricedIndividually = try XCTUnwrap(migratedProductBundleItemEntity.value(forKey: "pricedIndividually") as? Bool)
        XCTAssertFalse(pricedIndividually, "Confirm expected property exists, and is false by default.")
    }

    func test_migrating_from_104_to_105_removes_price_attribute_from_TopEarnerStatsItem_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 104")
        let sourceContext = sourceContainer.viewContext

        let topEarnerStatsItem = sourceContext.insert(entityName: "TopEarnerStatsItem", properties: [
            "productID": 1,
            "productName": "Product",
            "quantity": 1,
            "price": 4.99,
            "total": 4.99,
            "currency": "USD",
            "imageUrl": "https://example.com/woocommerce.jpg"
        ])
        try sourceContext.save()

        XCTAssertNotNil(topEarnerStatsItem.entity.attributesByName["price"], "Precondition. Attribute exists.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 105")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedtopEarnerStatsItem = try XCTUnwrap(targetContext.first(entityName: "TopEarnerStatsItem"))

        // The price attribute is removed from the migrated entity.
        XCTAssertNil(migratedtopEarnerStatsItem.entity.attributesByName["price"], "Confirm attribute no longer exists.")
    }

    func test_migrating_from_104_to_105_adds_BlazeTargetLanguage_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 104")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. `BlazeTargetLanguage` should not exist in Model 104
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "BlazeTargetLanguage", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 105")

        // Then
        let targetContext = targetContainer.viewContext

        // `BlazeTargetLanguage` should exist in Model 105
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "BlazeTargetLanguage", in: targetContext))
        XCTAssertEqual(try targetContext.count(entityName: "BlazeTargetLanguage"), 0)

        // Insert a new BlazeTargetLanguage
        let language = insertBlazeTargetLanguage(to: targetContext)
        XCTAssertEqual(try targetContext.count(entityName: "BlazeTargetLanguage"), 1)

        // Check all attributes
        XCTAssertEqual(language.value(forKey: "id") as? String, "en")
        XCTAssertEqual(language.value(forKey: "name") as? String, "English")
        XCTAssertEqual(language.value(forKey: "locale") as? String, "en")
    }

    func test_migrating_from_104_to_105_adds_BlazeTargetDevice_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 104")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. `BlazeTargetDevice` should not exist in Model 104
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "BlazeTargetDevice", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 105")

        // Then
        let targetContext = targetContainer.viewContext

        // `BlazeTargetDevice` should exist in Model 105
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "BlazeTargetDevice", in: targetContext))
        XCTAssertEqual(try targetContext.count(entityName: "BlazeTargetDevice"), 0)

        // Insert a new BlazeTargetDevice
        let device = insertBlazeTargetDevice(to: targetContext)
        XCTAssertEqual(try targetContext.count(entityName: "BlazeTargetDevice"), 1)

        // Check all attributes
        XCTAssertEqual(device.value(forKey: "id") as? String, "mobile")
        XCTAssertEqual(device.value(forKey: "name") as? String, "Mobile")
        XCTAssertEqual(device.value(forKey: "locale") as? String, "en")
    }

    func test_migrating_from_104_to_105_adds_BlazeTargetTopic_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 104")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. `BlazeTargetTopic` should not exist in Model 104
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "BlazeTargetTopic", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 105")

        // Then
        let targetContext = targetContainer.viewContext

        // `BlazeTargetTopic` should exist in Model 105
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "BlazeTargetTopic", in: targetContext))
        XCTAssertEqual(try targetContext.count(entityName: "BlazeTargetTopic"), 0)

        // Insert a new BlazeTargetTopic
        let topic = insertBlazeTargetTopic(to: targetContext)
        XCTAssertEqual(try targetContext.count(entityName: "BlazeTargetTopic"), 1)

        // Check all attributes
        XCTAssertEqual(topic.value(forKey: "id") as? String, "IAB1")
        XCTAssertEqual(topic.value(forKey: "name") as? String, "Arts & Entertainment")
        XCTAssertEqual(topic.value(forKey: "locale") as? String, "en")
    }

    func test_migrating_from_105_to_106_adds_OrderAttributionInfo_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 105")
        let sourceContext = sourceContainer.viewContext

        let order = insertOrder(to: sourceContext)
        try sourceContext.save()

        // Confidence Checks. This entity and relationship should not exist in Model 105.
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "OrderAttributionInfo", in: sourceContext))
        XCTAssertNil(order.entity.relationshipsByName["attributionInfo"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 106")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "Order"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "OrderAttributionInfo"), 0)

        // Migrated order has expected empty attributionInfo attribute.
        let migratedOrder = try XCTUnwrap(targetContext.firstObject(ofType: Order.self))
        XCTAssertNil(migratedOrder.value(forKey: "attributionInfo"))

        // Insert a new OrderAttributionInfo and add it to Order.
        let attributionInfo = insertOrderAttributionInfo(to: targetContext)
        migratedOrder.setValue(attributionInfo, forKey: "attributionInfo")
        try targetContext.save()

        // OrderAttributionInfo entity and attributes exist, including relationship with Order.
        XCTAssertEqual(try targetContext.count(entityName: "OrderAttributionInfo"), 1)
        XCTAssertNotNil(attributionInfo.value(forKey: "sourceType"))
        XCTAssertNotNil(attributionInfo.value(forKey: "campaign"))
        XCTAssertNotNil(attributionInfo.value(forKey: "source"))
        XCTAssertNotNil(attributionInfo.value(forKey: "medium"))
        XCTAssertNotNil(attributionInfo.value(forKey: "deviceType"))
        XCTAssertNotNil(attributionInfo.value(forKey: "sessionPageViews"))
        XCTAssertEqual(attributionInfo.value(forKey: "order") as? NSManagedObject, migratedOrder)

        // Order and OrderAttributionInfo relationship exists.
        XCTAssertEqual(migratedOrder.value(forKey: "attributionInfo") as? NSManagedObject, attributionInfo)
    }

    func test_migrating_from_106_to_107_adds_BlazeCampaignListItem_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 106")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. `BlazeCampaignListItem` should not exist in Model 106
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "BlazeCampaignListItem", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 107")

        // Then
        let targetContext = targetContainer.viewContext

        // `BlazeCampaignListItem` should exist in Model 107
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "BlazeCampaignListItem", in: targetContext))
        XCTAssertEqual(try targetContext.count(entityName: "BlazeCampaignListItem"), 0)

        // Insert a new BlazeCampaign
        let campaign = insertBlazeCampaignListItem(to: targetContext)
        XCTAssertEqual(try targetContext.count(entityName: "BlazeCampaignListItem"), 1)

        // Check all attributes
        XCTAssertNotNil(campaign.value(forKey: "siteID"))
        XCTAssertNotNil(campaign.value(forKey: "campaignID"))
        XCTAssertNotNil(campaign.value(forKey: "productID"))
        XCTAssertNotNil(campaign.value(forKey: "name"))
        XCTAssertNotNil(campaign.value(forKey: "textSnippet"))
        XCTAssertNotNil(campaign.value(forKey: "rawStatus"))
        XCTAssertNotNil(campaign.value(forKey: "imageURL"))
        XCTAssertNotNil(campaign.value(forKey: "targetUrl"))
        XCTAssertNotNil(campaign.value(forKey: "impressions"))
        XCTAssertNotNil(campaign.value(forKey: "clicks"))
        XCTAssertNotNil(campaign.value(forKey: "totalBudget"))
        XCTAssertNotNil(campaign.value(forKey: "spentBudget"))
    }

    func test_migrating_from_107_to_108_removes_BlazeCampaign_entity() throws {
        // Arrange
        let sourceContainer = try startPersistentContainer("Model 107")
        let sourceContext = sourceContainer.viewContext

        insertBlazeCampaign(to: sourceContext, forModel: 107)
        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "BlazeCampaign"), 1)

        let sourceEntitiesNames = sourceContainer.managedObjectModel.entitiesByName.keys
        XCTAssertTrue(sourceEntitiesNames.contains("BlazeCampaign"))

        // Action
        let targetContainer = try migrate(sourceContainer, to: "Model 108")
        let targetEntitiesNames = targetContainer.managedObjectModel.entitiesByName.keys

        // Assert
        XCTAssertFalse(targetEntitiesNames.contains("BlazeCampaign"))
    }

    func test_migrating_from_108_to_109_adds_new_budget_attributes_to_BlazeCampaignListItem() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 108")
        let sourceContext = sourceContainer.viewContext

        let campaign = insertBlazeCampaignListItem(to: sourceContext)
        try sourceContext.save()

        // Confidence check: new budget attributes are not present
        XCTAssertNil(campaign.entity.attributesByName["budgetAmount"])
        XCTAssertNil(campaign.entity.attributesByName["budgetCurrency"])
        XCTAssertNil(campaign.entity.attributesByName["budgetMode"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 109")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedEntity = try XCTUnwrap(targetContext.first(entityName: "BlazeCampaignListItem"))

        // Check default values for new budget attributes
        let budgetAmount = try XCTUnwrap(migratedEntity.value(forKey: "budgetAmount") as? Double)
        XCTAssertEqual(budgetAmount, 0)

        let budgetCurrency = try XCTUnwrap(migratedEntity.value(forKey: "budgetCurrency") as? String)
        XCTAssertEqual(budgetCurrency, "USD")

        let budgetMode = try XCTUnwrap(migratedEntity.value(forKey: "budgetMode") as? String)
        XCTAssertEqual(budgetMode, "total")
    }

    func test_migrating_from_109_to_110_adds_WCAnalyticsCustomer_and_WCAnalyticsCustomerSearchResult_entities() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 109")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. These entities should not exist in Model 109
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "WCAnalyticsCustomer", in: sourceContext))
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "WCAnalyticsCustomerSearchResult", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 110")

        // Then
        let targetContext = targetContainer.viewContext

        // These entities should exist in Model 110
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "WCAnalyticsCustomer", in: targetContext))
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "WCAnalyticsCustomerSearchResult", in: targetContext))
        XCTAssertEqual(try targetContext.count(entityName: "WCAnalyticsCustomer"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "WCAnalyticsCustomerSearchResult"), 0)

        // Insert a new WCAnalyticsCustomer
        let customer = insertWCAnalyticsCustomer(to: targetContext, forModel: 110)
        XCTAssertEqual(try targetContext.count(entityName: "WCAnalyticsCustomer"), 1)
        XCTAssertEqual(customer.value(forKey: "customerID") as? Int64, 1)

        // Insert a new WCAnalyticsCustomerSearchResult
        let customerSearchResult = targetContext.insert(
            entityName: "WCAnalyticsCustomerSearchResult",
            properties: [
                "siteID": 1,
                "keyword": ""
            ]
        )
        XCTAssertEqual(try targetContext.count(entityName: "WCAnalyticsCustomerSearchResult"), 1)
        XCTAssertEqual(customer.value(forKey: "customerID") as? Int64, 1)

        // Check all attributes
        XCTAssertNotNil(customerSearchResult.entity.attributesByName["siteID"])
        XCTAssertNotNil(customerSearchResult.entity.attributesByName["keyword"])
        XCTAssertNotNil(customer.entity.attributesByName["siteID"])
        XCTAssertNotNil(customer.entity.attributesByName["userID"])
        XCTAssertNotNil(customer.entity.attributesByName["name"])
        XCTAssertNotNil(customer.entity.attributesByName["email"])
        XCTAssertNotNil(customer.entity.attributesByName["username"])
        XCTAssertNotNil(customer.entity.attributesByName["dateLastActive"])
        XCTAssertNotNil(customer.entity.attributesByName["ordersCount"])
        XCTAssertNotNil(customer.entity.attributesByName["totalSpend"])
        XCTAssertNotNil(customer.entity.attributesByName["averageOrderValue"])
        XCTAssertNotNil(customer.entity.attributesByName["country"])
        XCTAssertNotNil(customer.entity.attributesByName["region"])
        XCTAssertNotNil(customer.entity.attributesByName["city"])
        XCTAssertNotNil(customer.entity.attributesByName["postcode"])
    }

    func test_migrating_from_110_to_111_adds_ShippingMethod_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 110")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. These entities should not exist in Model 110
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "ShippingMethod", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 111")

        // Then
        let targetContext = targetContainer.viewContext

        // These entities should exist in Model 110
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "ShippingMethod", in: targetContext))
        XCTAssertEqual(try targetContext.count(entityName: "ShippingMethod"), 0)

        // Insert a new ShippingMethod
        let shippingMethod = insertShippingMethod(to: targetContext, forModel: 111)
        XCTAssertEqual(try targetContext.count(entityName: "ShippingMethod"), 1)

        // Check all attributes
        XCTAssertNotNil(shippingMethod.entity.attributesByName["siteID"])
        XCTAssertNotNil(shippingMethod.entity.attributesByName["methodID"])
        XCTAssertNotNil(shippingMethod.entity.attributesByName["title"])
    }

    func test_migrating_from_111_to_112_updates_Site_entry() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 111")
        let sourceContext = sourceContainer.viewContext

        // Insert a new entity Site e sent the value of isPublic
        let site = NSEntityDescription.insertNewObject(forEntityName: "Site", into: sourceContext)
        site.setValue(true, forKey: "isPublic")
        try sourceContext.save()

        // Confidence Check. `isPublic` should check and `visibility` should not exist in Model 111
        let siteEntity = NSEntityDescription.entity(forEntityName: "Site", in: sourceContext)
        XCTAssertNotNil(siteEntity?.attributesByName["isPublic"])
        XCTAssertNil(siteEntity?.attributesByName["visibility"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 112")

        // Then
        let targetContext = targetContainer.viewContext

        // `isPublic` should not exist and `visibility` should exist in Model 112
        let migratedSiteEntity = NSEntityDescription.entity(forEntityName: "Site", in: targetContext)
        XCTAssertNil(migratedSiteEntity?.attributesByName["isPublic"])
        XCTAssertNotNil(migratedSiteEntity?.attributesByName["visibility"])

        // Retrieve the migrated Site
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Site")
        let migratedSites = try targetContext.fetch(fetchRequest)
        let migratedSite = try XCTUnwrap(migratedSites.first)

        // Verify that the `visibility` value is 1 (true converted to Int64)
        XCTAssertEqual(migratedSite.value(forKey: "visibility") as? Int64, 1)

        // Insert a new Site to verify that the new attribute can be set and saved correctly
        let newSite = NSEntityDescription.insertNewObject(forEntityName: "Site", into: targetContext)
        newSite.setValue(-1, forKey: "visibility")
        try targetContext.save()

        // Verify that the new attribute has been set correctly
        XCTAssertEqual(newSite.value(forKey: "visibility") as? Int64, -1)
    }

    func test_migrating_from_112_to_113_adds_new_password_attributes_to_Product() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 112")
        let sourceContext = sourceContainer.viewContext

        let product = insertProduct(to: sourceContext, forModel: 112)
        try sourceContext.save()

        XCTAssertNil(product.entity.attributesByName["password"], "Precondition. Property does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 113")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedProductEntity = try XCTUnwrap(targetContext.first(entityName: "Product"))

        XCTAssertNil(migratedProductEntity.value(forKey: "password") as? String, "Confirm expected property exists and is nil by default.")

        migratedProductEntity.setValue("test", forKey: "password")
        try targetContext.save()

        let password = try XCTUnwrap(migratedProductEntity.value(forKey: "password") as? String)
        XCTAssertEqual(password, "test", "Confirm expected property exists, and is false by default.")
    }

    func test_migrating_from_113_to_114_adds_new_attributes_to_BlazeCampaignListItem() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 113")
        let sourceContext = sourceContainer.viewContext

        let blazeCampaign = insertBlazeCampaignListItem(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(blazeCampaign.entity.attributesByName["isEvergreen"],
                     "Precondition. Property isEvergreen does not exist.")

        XCTAssertNil(blazeCampaign.entity.attributesByName["durationDays"],
                     "Precondition. Property durationDays does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 114")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedCampaignEntity = try XCTUnwrap(targetContext.first(entityName: "BlazeCampaignListItem"))

        XCTAssertEqual(migratedCampaignEntity.value(forKey: "isEvergreen") as? Bool, false, "Confirm property isEvergreen exists and is false by default.")

        XCTAssertEqual(migratedCampaignEntity.value(forKey: "durationDays") as? Int64, 0, "Confirm property durationDays exists and is 0 by default.")

        migratedCampaignEntity.setValue(true, forKey: "isEvergreen")
        migratedCampaignEntity.setValue(7, forKey: "durationDays")
        try targetContext.save()

        let isEvergreen = try XCTUnwrap(migratedCampaignEntity.value(forKey: "isEvergreen") as? Bool)
        let durationDays = try XCTUnwrap(migratedCampaignEntity.value(forKey: "durationDays") as? Int64)
        XCTAssertEqual(isEvergreen, true)
        XCTAssertEqual(durationDays, 7)
    }

    func test_migrating_from_114_to_115_adds_BlazeCampaignObjective_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 114")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. These entities should not exist in Model 114
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "BlazeCampaignObjective", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 115")

        // Then
        let targetContext = targetContainer.viewContext

        // These entities should exist in Model 110
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "BlazeCampaignObjective", in: targetContext))
        XCTAssertEqual(try targetContext.count(entityName: "BlazeCampaignObjective"), 0)

        // Insert a new BlazeCampaignObjective
        let objective = insertBlazeCampaignObjective(to: targetContext)
        XCTAssertEqual(try targetContext.count(entityName: "BlazeCampaignObjective"), 1)

        // Check all attributes
        XCTAssertNotNil(objective.entity.attributesByName["id"])
        XCTAssertNotNil(objective.entity.attributesByName["title"])
        XCTAssertNotNil(objective.entity.attributesByName["generalDescription"])
        XCTAssertNotNil(objective.entity.attributesByName["suitableForDescription"])
    }

    func test_migrating_from_114_to_115_renames_OrderMetaData_to_MetaData() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 114")
        let sourceContext = sourceContainer.viewContext

        let order = insertOrder(to: sourceContext)
        let orderMetaData = insertOrderMetaData(to: sourceContext)
        order.setValue(NSSet(array: [orderMetaData]), forKey: "customFields")
        try sourceContext.save()

        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "OrderMetaData", in: sourceContext))
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "MetaData", in: sourceContext))
        XCTAssertEqual(try sourceContext.count(entityName: "OrderMetaData"), 1)

        let originalOrderMetaData = try XCTUnwrap(sourceContext.first(entityName: "OrderMetaData"))
        let originalAttributes = originalOrderMetaData.entity.attributesByName.keys.reduce(into: [String: Any]()) { result, key in
            result[key] = originalOrderMetaData.value(forKey: key)
        }

        // When

        // Before migrating, confirm that doing lightweight migration is possible
        // see: https://developer.apple.com/documentation/coredata/migrating_your_data_model_automatically#2903987
        let sourceModel = try XCTUnwrap(modelsInventory.model(for: .init(name: "Model 114")))
        let destinationModel = try XCTUnwrap(modelsInventory.model(for: .init(name: "Model 115")))
        let inferredMappingModel = try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
        XCTAssertNotNil(inferredMappingModel, "Failed to infer mapping model. This may indicate that a heavyweight migration is required.")

        // Start migration
        let targetContainer = try migrate(sourceContainer, to: "Model 115")
        let targetContext = targetContainer.viewContext

        // Then
        // Check that OrderMetaData entity no longer exists
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "OrderMetaData", in: targetContext))

        // Check that MetaData entity exists
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "MetaData", in: targetContext))

        // Check that the data has been migrated
        XCTAssertEqual(try targetContext.count(entityName: "MetaData"), 1)

        // Check that the relationship with Order is correct and compare migrated data
        let migratedOrder = try XCTUnwrap(targetContext.first(entityName: "Order"))
        let migratedMetaData = try XCTUnwrap(migratedOrder.value(forKey: "customFields") as? NSSet)
        XCTAssertEqual(migratedMetaData.count, 1)

        let migratedMetaDataObject = try XCTUnwrap(migratedMetaData.anyObject() as? NSManagedObject)
        XCTAssertTrue(migratedMetaDataObject.entity.name == "MetaData")

        // Compare attribute values
        for (attribute, originalValue) in originalAttributes {
            let migratedValue = migratedMetaDataObject.value(forKey: attribute)
            XCTAssertEqual(originalValue as? NSObject, migratedValue as? NSObject, "Attribute '\(attribute)' mismatch")
        }

        // Test adding new MetaData
        let newMetaData = insertMetaData(to: targetContext)
        migratedOrder.mutableSetValue(forKey: "customFields").add(newMetaData)
        try targetContext.save()

        XCTAssertEqual(try targetContext.count(entityName: "MetaData"), 2)
        XCTAssertEqual((migratedOrder.value(forKey: "customFields") as? NSSet)?.count, 2)
    }

    func test_migrating_from_115_to_116_adds_new_startTime_attribute_to_BlazeCampaignListItem() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 115")
        let sourceContext = sourceContainer.viewContext

        let campaign = insertBlazeCampaignListItem(to: sourceContext)
        try sourceContext.save()

        XCTAssertEqual(try sourceContext.count(entityName: "BlazeCampaignListItem"), 1)

        // Confidence check: new startTime attribute is not present
        XCTAssertNil(campaign.entity.attributesByName["startTime"])

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 116")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedEntity = try XCTUnwrap(targetContext.first(entityName: "BlazeCampaignListItem"))

        XCTAssertNil(migratedEntity.value(forKey: "startTime") as? Date, "Confirm expected property exists and is nil by default.")

        let startTimeDate = Date(timeIntervalSince1970: 1603250786)
        migratedEntity.setValue(startTimeDate, forKey: "startTime")
        try targetContext.save()

        let startTime = try XCTUnwrap(migratedEntity.value(forKey: "startTime") as? Date)
        XCTAssertEqual(startTime, startTimeDate, "Confirm expected property exists, and has expected date.")
    }
}

// MARK: - Persistent Store Setup and Migrations

private extension MigrationTests {
    /// Create a new Sqlite file and load it. Returns the loaded `NSPersistentContainer`.
    func startPersistentContainer(_ versionName: String) throws -> NSPersistentContainer {
        let storeURL = try XCTUnwrap(NSURL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)?
            .appendingPathExtension("sqlite"))
        let model = try XCTUnwrap(modelsInventory.model(for: .init(name: versionName)))
        let container = makePersistentContainer(storeURL: storeURL, model: model)

        let loadingError: Error? = waitFor { promise in
            container.loadPersistentStores { _, error in
                promise(error)
            }
        }
        XCTAssertNil(loadingError)

        return container
    }

    /// Migrate the existing `container` to the model with name `versionName`.
    ///
    /// This disconnects the given `container` from the `NSPersistentStore` (SQLite) to avoid
    /// warnings pertaining to having two `NSPersistentContainer` using the same SQLite file.
    /// The `container.viewContext` and any created `NSManagedObjects` can still be used but
    /// they will not be attached to the SQLite database so watch out for that. XD
    ///
    /// - Returns: A new `NSPersistentContainer` instance using the new `NSManagedObjectModel`
    ///            pointed to by `versionName`.
    ///
    func migrate(_ container: NSPersistentContainer, to versionName: String) throws -> NSPersistentContainer {
        let storeDescription = try XCTUnwrap(container.persistentStoreDescriptions.first)
        let storeURL = try XCTUnwrap(storeDescription.url)
        let targetModel = try XCTUnwrap(modelsInventory.model(for: .init(name: versionName)))

        // Unload the currently loaded persistent store to avoid Sqlite warnings when we create
        // another NSPersistentContainer later after the upgrade.
        let persistentStore = try XCTUnwrap(container.persistentStoreCoordinator.persistentStore(for: storeURL))
        try container.persistentStoreCoordinator.remove(persistentStore)

        // Migrate the store
        let migrator = CoreDataIterativeMigrator(coordinator: container.persistentStoreCoordinator,
                                                 modelsInventory: modelsInventory)
        let (isMigrationSuccessful, _) =
            try migrator.iterativeMigrate(sourceStore: storeURL, storeType: storeDescription.type, to: targetModel)
        XCTAssertTrue(isMigrationSuccessful)

        // Load a new container
        let migratedContainer = makePersistentContainer(storeURL: storeURL, model: targetModel)
        let loadingError: Error? = waitFor { promise in
            migratedContainer.loadPersistentStores { _, error in
                promise(error)
            }
        }
        XCTAssertNil(loadingError)

        return migratedContainer
    }

    func makePersistentContainer(storeURL: URL, model: NSManagedObjectModel) -> NSPersistentContainer {
        let description: NSPersistentStoreDescription = {
            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldAddStoreAsynchronously = false
            description.shouldMigrateStoreAutomatically = false
            description.type = NSSQLiteStoreType
            return description
        }()

        let container = NSPersistentContainer(name: "ContainerName", managedObjectModel: model)
        container.persistentStoreDescriptions = [description]

        createdStoreURLs.insert(storeURL)

        return container
    }
}

// MARK: - Entity Helpers
//

private extension MigrationTests {
    /// Inserts a `Customer` entity, providing default values for the required properties.
    @discardableResult
    func insertCustomer(to context: NSManagedObjectContext, forModel modelVersion: Int) -> NSManagedObject {
        let customer = context.insert(entityName: "Customer", properties: [
            "customerID": 1,
            "email": "",
            "firstName": "",
            "lastName": "",
            "billingAddress1": "",
            "billingAddress2": "",
            "billingCity": "",
            "billingCompany": "",
            "billingCountry": "",
            "billingEmail": "",
            "billingFirstName": "",
            "billingLastName": "",
            "billingPhone": "",
            "billingPostcode": "",
            "billingState": "",
            "shippingAddress1": "",
            "shippingAddress2": "",
            "shippingCity": "",
            "shippingCompany": "",
            "shippingCountry": "",
            "shippingEmail": "",
            "shippingFirstName": "",
            "shippingLastName": "",
            "shippingPhone": "",
            "shippingPostcode": "",
            "shippingState": ""
        ])

        // Required since model 75
        if modelVersion >= 75 {
            customer.setValue(1, forKey: "siteID")
        }

        return customer
    }

    /// Inserts a `ProductVariation` entity, providing default values for the required properties.
    @discardableResult
    func insertProductVariation(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "ProductVariation", properties: [
            "dateCreated": Date(),
            "backordered": false,
            "backordersAllowed": false,
            "backordersKey": "",
            "permalink": "",
            "price": "",
            "statusKey": "",
            "stockStatusKey": "",
            "taxStatusKey": ""
        ])
    }

    @discardableResult
    func insertAccount(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "Account", properties: [
            "userID": 0,
            "username": ""
        ])
    }

    @discardableResult
    func insertCoupon(to context: NSManagedObjectContext,
                      limitUsageToXItems: Int64? = 3,
                      usageLimitPerUser: Int64? = 1,
                      usageLimit: Int64? = 1000) -> NSManagedObject {
        context.insert(entityName: "Coupon", properties: [
            "couponID": 123123,
            "maximumAmount": "12.00",
            "minimumAmount": "1.00",
            "excludeSaleItems": true,
            "freeShipping": false,
            "limitUsageToXItems": limitUsageToXItems,
            "usageLimitPerUser": usageLimitPerUser,
            "usageLimit": usageLimit,
            "individualUse": true,
            "usageCount": 200,
            "dateExpires": Date(),
            "fullDescription": "Coupon for getting discounts",
            "discountType": "fixed_cart",
            "dateModified": Date(),
            "dateCreated": Date(),
            "amount": "2.00",
            "code": "2off2021",
            "usedBy": ["me@example.com"],
            "emailRestrictions": ["*@woocommerce.com"],
            "siteID": 1212,
            "products": [1231, 111],
            "excludedProducts": [19182, 192],
            "productCategories": [1092281],
            "excludedProductCategories": [128121212]
        ])
    }

    @discardableResult
    func insertCouponSearchResult(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "CouponSearchResult", properties: ["keyword": "test"])
    }

    @discardableResult
    func insertInboxNote(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "InboxNote", properties: [
            "id": 123123,
            "name": "wc-admin-wc-helper-subscription",
            "type": "warning",
            "status": "unactioned",
            "title": "WooCommerce Bookings subscription expired",
            "content": "Your subscription expired on October 22nd. Get a new subscription to continue receiving updates and access to support.",
            "isRemoved": false,
            "isRead": false,
            "dateCreated": Date()
        ])
    }

    @discardableResult
    func insertInboxAction(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "InboxAction", properties: [
            "id": 13329,
            "name": "renew-subscription",
            "label": "Renew Subscription",
            "status": "actioned",
            "url": "https://woocommerce.com/products/woocommerce-bookings/"
        ])
    }

    @discardableResult
    func insertOrder(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "Order", properties: [
            "orderID": 134,
            "statusKey": ""
        ])
    }

    @discardableResult
    func insertOrderItem(itemID: Int64 = 134, to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "OrderItem", properties: [
            "itemID": itemID
        ])
    }

    @discardableResult
    func insertOrderItemAttribute(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "OrderItemAttribute", properties: [
            "metaID": 134,
            "name": "Woo",
            "value": "4.7"
        ])
    }

    @discardableResult
    func insertOrderFeeLine(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "OrderFeeLine", properties: [
            "feeID": 134,
            "name": "Woo",
            "total": "125.0"
        ])
    }

    @discardableResult
    func insertOrderTaxLine(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "OrderTaxLine", properties: [
            "taxID": 134,
            "label": "State",
            "ratePercent": 5.0
        ])
    }

    @discardableResult
    func insertRefund(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "Refund", properties: [
            "refundID": 123,
            "orderID": 234,
            "siteID": 345,
            "byUserID": 456,
            "isAutomated": false,
            "createAutomated": false
        ])
    }

    @discardableResult
    func insertOrderItemRefund(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "OrderItemRefund", properties: [
            "itemID": 123
        ])
    }

    @discardableResult
    func insertProduct(to context: NSManagedObjectContext, forModel modelVersion: Int) -> NSManagedObject {
        let product = context.insert(entityName: "Product", properties: [
            "price": "",
            "permalink": "",
            "productTypeKey": "simple",
            "purchasable": true,
            "averageRating": "",
            "backordered": true,
            "backordersAllowed": false,
            "backordersKey": "",
            "catalogVisibilityKey": "",
            "dateCreated": Date(),
            "downloadable": true,
            "featured": true,
            "manageStock": true,
            "name": "product",
            "onSale": true,
            "soldIndividually": true,
            "slug": "",
            "shippingRequired": false,
            "shippingTaxable": false,
            "reviewsAllowed": true,
            "groupedProducts": [Int64](),
            "virtual": true,
            "stockStatusKey": "",
            "statusKey": "",
            "taxStatusKey": ""
        ])

        // Required since model 33
        if modelVersion >= 33 {
            product.setValue(Date(), forKey: "Date")
        }

        // Field available from model 113
        if modelVersion >= 113 {
            product.setValue("test", forKey: "password")
        }

        return product
    }

    @discardableResult
    func insertProductCategory(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "ProductCategory", properties: [
            "name": "",
            "slug": ""
        ])
    }

    func insertProductAttributeTerm(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "ProductAttributeTerm", properties: [
            "name": "New Term",
            "slug": "new_term"
        ])
    }

    @discardableResult
    func insertProductTag(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "ProductTag", properties: [
            "tagID": 0,
            "name": "",
            "slug": ""
        ])
    }

    @discardableResult
    func insertProductAttribute(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "ProductAttribute", properties: [
            "name": "",
            "variation": false,
            "visible": false
        ])
    }

    @discardableResult
    func insertShippingLabel(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "ShippingLabel", properties: [
            "siteID": 134,
            "shippingLabelID": 1216,
            "carrierID": "fedex",
            "dateCreated": Date(),
            "packageName": "Fancy box",
            "rate": 12.6,
            "currency": "USD",
            "trackingNumber": "B134",
            "serviceName": "Fedex",
            "refundableAmount": 13.4,
            "status": "PURCHASED",
            "productIDs": [1216, 1126],
            "productNames": ["Choco", "Latte"]
        ])
    }

    @discardableResult
    func insertShippingLabelAddress(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "ShippingLabelAddress", properties: [
            "company": "Chococo co.",
            "name": "Choco",
            "phone": "+16501234567",
            "country": "USA",
            "state": "PA",
            "address1": "123 ABC Street",
            "address2": "",
            "city": "Ph",
            "postcode": "18888"
        ])
    }

    @discardableResult
    func insertShippingLabelRefund(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "ShippingLabelRefund", properties: [
            "dateRequested": Date(),
            "status": "pending"
        ])
    }

    @discardableResult
    func insertShippingLabelSettings(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "ShippingLabelSettings", properties: [
            "siteID": 134,
            "orderID": 191,
            "paperSize": "legal"
        ])
    }

    @discardableResult
    func insertOrderStatsTotals(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "OrderStatsV4Totals", properties: [
            "totalOrders": 3,
            "totalItemsSold": 5,
            "grossRevenue": 800,
            "couponDiscount": 0,
            "totalCoupons": 0,
            "refunds": 0,
            "taxes": 0,
            "shipping": 0,
            "netRevenue": 800,
            "totalProducts": 2,
        ])
    }

    @discardableResult
    func insertSiteSummaryStats(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "SiteSummaryStats", properties: [
            "date": "2022-12-15",
            "period": "day",
            "visitors": 3,
            "views": 9
        ])
    }

    @discardableResult
    func insertSiteVisitStats(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "SiteVisitStats", properties: [
            "date": "2021-01-22",
            "granularity": "day"
        ])
    }

    @discardableResult
    func insertSiteVisitStatsItem(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "SiteVisitStatsItem", properties: [
            "period": "day",
            "visitors": 3
        ])
    }

    @discardableResult
    func insertTopEarnerStats(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "TopEarnerStats", properties: [
            "date": "2021-01-22",
            "granularity": "day",
            "limit": "3"
        ])
    }

    @discardableResult
    func insertAccountSettingsWithoutFirstNameAndLastName(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "AccountSettings", properties: [
            "userID": 0,
            "tracksOptOut": true
        ])
    }

    @discardableResult
    func insertSitePlugin(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "SitePlugin", properties: [
            "siteID": 1372,
            "plugin": "hello",
            "status": "inactive",
            "name": "Hello Dolly",
            "pluginUri": "http://wordpress.org/plugins/hello-dolly/",
            "author": "Matt Mullenweg",
            "authorUri": "http://ma.tt/",
            "descriptionRaw": "This is not just a plugin, it...",
            "descriptionRendered": "This is not just a plugin, it symbolizes...",
            "version": "1.7.2",
            "networkOnly": false,
            "requiresWPVersion": "",
            "requiresPHPVersion": "",
            "textDomain": ""
        ])
    }

    @discardableResult
    func insertPaymentGateway(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "PaymentGateway", properties: [
            "siteID": 1372,
            "gatewayID": "woocommerce-payments",
            "title": "WooCommerce Payments",
            "gatewayDescription": "WooCommerce Payments - easy payments by Woo",
            "enabled": true,
            "features": [String]()
        ])
    }

    @discardableResult
    func insertPaymentGatewayAccount(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "PaymentGatewayAccount", properties: [
            "siteID": 1372,
            "statementDescriptor": "STAGING.MARS",
            "isCardPresentEligible": false,
            "hasPendingRequirements": false,
            "hasOverdueRequirements": false,
            "currentDeadline": NSDate(),
            "defaultCurrency": "USD",
            "country": "US",
            "supportedCurrencies": ["USD"],
            "status": "complete",
            "gatewayID": "woocommerce-payments"
        ])
    }

    @discardableResult
    func insertOrderCount(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "OrderCount", properties: [
            "siteID": 123
        ])
    }

    @discardableResult
    func insertOrderCountItem(slug: String, to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "OrderCountItem", properties: [
            "slug": slug,
            "name": slug,
            "total": 6
        ])
    }

    @discardableResult
    func insertCountry(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "Country", properties: [
            "code": "DZ",
            "name": "Algeria"
        ])
    }

    @discardableResult
    func insertStateOfACountry(code: String, name: String, to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "StateOfACountry", properties:
            ["code": code, "name": name])
    }

    @discardableResult
    func insertSystemPlugin(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "SystemPlugin", properties: [
            "siteID": 1372,
            "plugin": "hello",
            "name": "Hello Dolly",
            "url": "http://wordpress.org/plugins/hello-dolly/",
            "authorName": "Matt Mullenweg",
            "authorUrl": "http://ma.tt/",
            "version": "1.7.2",
            "versionLatest": "1.7.2",
            "networkActivated": false
        ])
    }

    @discardableResult
    func insertSite(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "Site", properties: [
            "siteID": 1372
        ])
    }

    @discardableResult
    func insertWCPayCharge(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "WCPayCharge", properties: [
            "siteID": 1234,
            "chargeID": "ch_idhash",
            "amount": 12,
            "amountCaptured": 12,
            "amountRefunded": 3,
            "authorizationCode": nil,
            "captured": true,
            "created": Date(),
            "currency": "usd",
            "paid": true,
            "paymentIntentID": nil,
            "paymentMethodID": "pm_idhash",
            "refunded": false,
            "status": "succeeded"
        ])
    }

    @discardableResult
    func insertWCPayCardPresentReceiptDetails(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "WCPayCardPresentReceiptDetails", properties: [
            "accountType": "credit",
            "applicationPreferredName": "Stripe Credit",
            "dedicatedFileName": "293AAABBBCCCCC2"
        ])
    }

    @discardableResult
    func insertWCPayCardPresentPaymentDetails(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "WCPayCardPresentPaymentDetails", properties: [
            "brand": "amex",
            "last4": "1932",
            "funding": "credit"
        ])
    }

    @discardableResult
    func insertWCPayCardPaymentDetails(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "WCPayCardPaymentDetails", properties: [
            "brand": "visa",
            "last4": "2096",
            "funding": "debit"
        ])
    }

    @discardableResult
    func insertOrderMetaData(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "OrderMetaData", properties: [
            "metadataID": 18148,
            "key": "Viewed Currency",
            "value": "USD"
        ])
    }

    @discardableResult
    func insertProductSearchResults(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "ProductSearchResults", properties: [
            "keyword": "soul"
        ])
    }

    @discardableResult
    func insertProductBundleItem(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "ProductBundleItem", properties: [
            "bundledItemID": 12,
            "menuOrder": 0,
            "productID": 1,
            "stockStatus": "in_stock",
            "title": ""
        ])
    }

    @discardableResult
    func insertCompositeComponent(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "ProductCompositeComponent", properties: [
            "componentID": "1679310855",
            "title": "Camera Body",
            "imageURL": "https://example.com/woocommerce.jpg",
            "optionType": "product_ids",
            "optionIDs": [413, 412]
        ])
    }

    @discardableResult
    func insertProductSubscription(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "ProductSubscription", properties: [
            "length": "2",
            "period": "month",
            "periodInterval": "1",
            "price": "5",
            "signUpFee": "",
            "trialLength": "1",
            "trialPeriod": "week"
        ])
    }

    @discardableResult
    func insertOrderGiftCard(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "OrderGiftCard", properties: [
            "giftCardID": 2,
            "code": "SU9F-MGB5-KS5V-EZFT",
            "amount": 20
        ])
    }

    @discardableResult
    func insertOrderAttributionInfo(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "OrderAttributionInfo", properties: [
            "sourceType": "referral",
            "campaign": "sale",
            "source": "woocommerce.com",
            "medium": "referral",
            "deviceType": "Desktop",
            "sessionPageViews": "2"
        ])
    }

    @discardableResult
    func insertOrderItemProductAddOn(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "OrderItemProductAddOn", properties: [
            "addOnID": 645,
            "key": "Sugar level",
            "value": "Zero"
        ])
    }

    @discardableResult
    func insertTaxRate(to context: NSManagedObjectContext, forModel modelVersion: Int) -> NSManagedObject {
        let taxRate = context.insert(entityName: "TaxRate", properties: [
            "id": 123123,
            "country": "US",
            "state": "FL",
            "postcode": "1234",
            "postcodes": ["1234"],
            "priority": 1,
            "name": "State Tax",
            "order": 1,
            "taxRateClass": "standard",
            "shipping": true,
            "compound": true,
            "city": "Miami",
            "cities": ["Miami"]
        ])

        if modelVersion >= 96 {
            taxRate.setValue(1, forKey: "siteID")
        }

        return taxRate
    }

    /// Inserts a `BlazeCampaign` entity, providing default values for the required properties.
    @discardableResult
    func insertBlazeCampaign(to context: NSManagedObjectContext, forModel modelVersion: Int) -> NSManagedObject {
        let campaign = context.insert(entityName: "BlazeCampaign", properties: [
            "campaignID": 1,
            "contentClickURL": "https://example.com/products/1",
            "contentImageURL": "https://example.com/products/1/thumbnail.png",
            "name": "Product",
            "rawStatus": "approved",
            "totalBudget": 150,
            "totalClicks": 11,
            "totalImpressions": 33
        ])

        // Required since model 100
        if modelVersion >= 100 {
            campaign.setValue(1, forKey: "siteID")
        }

        // Required since model 101
        if modelVersion >= 101 {
            campaign.setValue(NSNumber(value: 123), forKey: "productID")
        }

        return campaign
    }

    /// Inserts a `BlazeCampaignListItem` entity, providing default values for the required properties.
    @discardableResult
    func insertBlazeCampaignListItem(to context: NSManagedObjectContext) -> NSManagedObject {
        let campaign = context.insert(entityName: "BlazeCampaignListItem", properties: [
            "siteID": 1,
            "campaignID": "1",
            "productID": NSNumber(value: 123),
            "name": "Amazing deals!",
            "textSnippet": "Get now.",
            "rawStatus": "approved",
            "imageURL": "https://example.com/products/1/thumbnail.png",
            "targetUrl": "https://example.com/products/1",
            "impressions": 150,
            "clicks": 21,
            "totalBudget": 35,
            "spentBudget": 5
        ])
        return campaign
    }

    /// Inserts a `BlazeTargetLanguage` entity, providing default values for the required properties.
    @discardableResult
    func insertBlazeTargetLanguage(to context: NSManagedObjectContext) -> NSManagedObject {
        let language = context.insert(entityName: "BlazeTargetLanguage", properties: [
            "id": "en",
            "name": "English",
            "locale": "en"
        ])
        return language
    }

    /// Inserts a `BlazeTargetDevice` entity, providing default values for the required properties.
    @discardableResult
    func insertBlazeTargetDevice(to context: NSManagedObjectContext) -> NSManagedObject {
        let device = context.insert(entityName: "BlazeTargetDevice", properties: [
            "id": "mobile",
            "name": "Mobile",
            "locale": "en"
        ])
        return device
    }

    /// Inserts a `BlazeTargetTopic` entity, providing default values for the required properties.
    @discardableResult
    func insertBlazeTargetTopic(to context: NSManagedObjectContext) -> NSManagedObject {
        let topic = context.insert(entityName: "BlazeTargetTopic", properties: [
            "id": "IAB1",
            "name": "Arts & Entertainment",
            "locale": "en"
        ])
        return topic
    }

    /// Inserts a `WCAnalyticsCustomer` entity, providing default values for the required properties.
    @discardableResult
    func insertWCAnalyticsCustomer(to context: NSManagedObjectContext, forModel modelVersion: Int) -> NSManagedObject {
        let customer = context.insert(entityName: "WCAnalyticsCustomer", properties: [
            "siteID": 1,
            "customerID": 1,
            "userID": 1,
            "name": "John",
            "email": "john.doe@example.com",
            "username": "john",
            "dateRegistered": nil,
            "dateLastActive": Date(),
            "ordersCount": 1,
            "totalSpend": 10,
            "averageOrderValue": 10,
            "country": "US",
            "city": "San Francisco",
            "region": "CA",
            "postcode": "94103"
        ])
        return customer
    }

    /// Inserts a `ShippingMethod` entity, providing default values for the required properties.
    @discardableResult
    func insertShippingMethod(to context: NSManagedObjectContext, forModel modelVersion: Int) -> NSManagedObject {
        let method = context.insert(entityName: "ShippingMethod", properties: [
            "siteID": 1,
            "methodID": "flat_rate",
            "title": "Flat rate"
        ])
        return method
    }

    @discardableResult
    func insertBlazeCampaignObjective(to context: NSManagedObjectContext) -> NSManagedObject {
        let method = context.insert(entityName: "BlazeCampaignObjective", properties: [
            "id": "sales",
            "title": "Sales",
            "generalDescription": "Converts potential customers into buyers by encouraging purchase.",
            "suitableForDescription": "E-commerce, retailers, subscription services."
        ])
        return method
    }

    @discardableResult
    func insertMetaData(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "MetaData", properties: [
            "metadataID": 18149,
            "key": "New Metadata Key",
            "value": "New Metadata Value"
        ])
    }
}
