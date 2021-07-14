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
    func insertOrder(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "Order", properties: [
            "orderID": 134,
            "statusKey": ""
        ])
    }

    @discardableResult
    func insertOrderItem(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "OrderItem", properties: [
            "itemID": 134
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
            "groupedProducts": [],
            "virtual": true,
            "stockStatusKey": "",
            "statusKey": "",
            "taxStatusKey": ""
        ])

        // Required since model 33
        if modelVersion >= 33 {
            product.setValue(Date(), forKey: "Date")
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
    func insertSiteVisitStats(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "SiteVisitStats", properties: [
            "date": "2021-01-22",
            "granularity": "day"
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
}
