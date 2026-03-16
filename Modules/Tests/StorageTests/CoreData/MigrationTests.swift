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
        modelsInventory = try .from(packageName: "WooCommerce", bundle: .storage)
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

    func test_migrating_from_116_to_117_adds_customFields_property_to_Product() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 116")
        let sourceContext = sourceContainer.viewContext

        let product = insertProduct(to: sourceContext, forModel: 116)
        try sourceContext.save()

        // `customFields` should not be present before migration
        XCTAssertNil(product.entity.relationshipsByName["customFields"])

        // Make sure product exist in model 115
        XCTAssertEqual(try sourceContext.count(entityName: "Product"), 1)

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 117")
        let targetContext = targetContainer.viewContext

        // Confidence check
        XCTAssertEqual(try targetContext.count(entityName: "Product"), 1)
        XCTAssertEqual(try targetContext.count(entityName: "MetaData"), 0)

        let migratedProduct = try XCTUnwrap(targetContext.first(entityName: "Product"))

        // `customFields` should be present in `migratedProduct`
        XCTAssertNotNil(migratedProduct.entity.relationshipsByName["customFields"])

        // Test adding custom fields to a migrated `Product`.
        let customField = insertMetaData(to: targetContext)
        migratedProduct.mutableSetValue(forKey: "customFields").add(customField)

        XCTAssertNoThrow(try targetContext.save())

        // Confidence check
        XCTAssertEqual(try targetContext.count(entityName: "MetaData"), 1)

        // The relationship between Product and MetaData should be updated.
        XCTAssertEqual(migratedProduct.value(forKey: "customFields") as? Set<NSManagedObject>, [customField])

        // The MetaData.product inverse relationship should be updated.
        XCTAssertEqual(customField.value(forKey: "product") as? NSManagedObject, migratedProduct)
    }

    func test_migrating_from_117_to_118_adds_new_globalUniqueID_attribute_in_product() throws {
		// Given
		let sourceContainer = try startPersistentContainer("Model 117")
		let sourceContext = sourceContainer.viewContext

		let product = insertProduct(to: sourceContext, forModel: 117)
		try sourceContext.save()

		XCTAssertNil(product.entity.attributesByName["globalUniqueID"], "Precondition. Property does not exist.")

		// When
		let targetContainer = try migrate(sourceContainer, to: "Model 118")

		// Then
		let targetContext = targetContainer.viewContext
		let migratedProduct = try XCTUnwrap(targetContext.first(entityName: "Product"))

		// `globalUniqueID` should be present in `migratedProduct`
		XCTAssertNotNil(migratedProduct.entity.attributesByName["globalUniqueID"])

		let globalUniqueID = "1223"
		migratedProduct.setValue(globalUniqueID, forKey: "globalUniqueID")
		try targetContext.save()

		let savedGlobalUniqueID = try XCTUnwrap(migratedProduct.value(forKey: "globalUniqueID") as? String)
		XCTAssertEqual(savedGlobalUniqueID, globalUniqueID)
	}

	func test_migrating_from_117_to_118_adds_new_globalUniqueID_attribute_in_product_variation() throws {
		// Given
		let sourceContainer = try startPersistentContainer("Model 117")
		let sourceContext = sourceContainer.viewContext

		let product = insertProductVariation(to: sourceContext)
		try sourceContext.save()

		XCTAssertNil(product.entity.attributesByName["globalUniqueID"], "Precondition. Property does not exist.")

		// When
		let targetContainer = try migrate(sourceContainer, to: "Model 118")

		// Then
		let targetContext = targetContainer.viewContext
		let migratedProductVariation = try XCTUnwrap(targetContext.first(entityName: "ProductVariation"))

		// `globalUniqueID` should be present in `migratedProductVariation`
		XCTAssertNotNil(migratedProductVariation.entity.attributesByName["globalUniqueID"])

		let globalUniqueID = "1223"
		migratedProductVariation.setValue(globalUniqueID, forKey: "globalUniqueID")
		try targetContext.save()

		let savedGlobalUniqueID = try XCTUnwrap(migratedProductVariation.value(forKey: "globalUniqueID") as? String)
		XCTAssertEqual(savedGlobalUniqueID, globalUniqueID)
	}

    func test_migrating_from_118_to_119_adds_woo_shipping_entities() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 118")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. These entities should not exist in Model 118
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "WooShippingPackagesResponse", in: sourceContext))
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "WooShippingCarrierPredefinedOptions", in: sourceContext))
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "WooShippingCustomPackage", in: sourceContext))
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "WooShippingPredefinedOption", in: sourceContext))
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "WooShippingPredefinedPackage", in: sourceContext))
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "WooShippingSavedPredefinedPackage", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 119")

        // Then
        let targetContext = targetContainer.viewContext

        // These entities should exist in Model 119
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "WooShippingPackagesResponse", in: targetContext))
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "WooShippingCarrierPredefinedOptions", in: targetContext))
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "WooShippingCustomPackage", in: targetContext))
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "WooShippingPredefinedOption", in: targetContext))
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "WooShippingPredefinedPackage", in: targetContext))
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "WooShippingSavedPredefinedPackage", in: targetContext))

        XCTAssertEqual(try targetContext.count(entityName: "WooShippingPackagesResponse"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "WooShippingCarrierPredefinedOptions"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "WooShippingCustomPackage"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "WooShippingPredefinedOption"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "WooShippingPredefinedPackage"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "WooShippingSavedPredefinedPackage"), 0)

        // Insert a new WooShippingCarrierPackagesResponse
        let packagesResponse = insertWooShippingPackagesResponse(to: targetContext)
        XCTAssertEqual(try targetContext.count(entityName: "WooShippingPackagesResponse"), 1)

        // Check all attributes and relationships
        XCTAssertNotNil(packagesResponse.entity.attributesByName["siteID"])
        XCTAssertNotNil(packagesResponse.entity.relationshipsByName["allPredefinedOptions"])
        XCTAssertNotNil(packagesResponse.entity.relationshipsByName["customPackages"])
        XCTAssertNotNil(packagesResponse.entity.relationshipsByName["savedPredefinedPackages"])

        // Insert a new WooShippingCarrierPredefinedOptions
        let carrierPredefinedOptions = insertWooShippingCarrierPredefinedOptions(to: targetContext)
        XCTAssertEqual(try targetContext.count(entityName: "WooShippingCarrierPredefinedOptions"), 1)

        // Check all attributes and relationships
        XCTAssertNotNil(carrierPredefinedOptions.entity.attributesByName["carrierID"])
        XCTAssertNotNil(carrierPredefinedOptions.entity.relationshipsByName["predefinedOptions"])

        // Insert a new WooShippingPredefinedOption
        let predefinedOption = insertWooShippingPredefinedOption(to: targetContext)
        XCTAssertEqual(try targetContext.count(entityName: "WooShippingPredefinedOption"), 1)

        // Check all attributes and relationships
        XCTAssertNotNil(predefinedOption.entity.attributesByName["providerID"])
        XCTAssertNotNil(predefinedOption.entity.attributesByName["title"])
        XCTAssertNotNil(predefinedOption.entity.relationshipsByName["carrier"])
        XCTAssertNotNil(predefinedOption.entity.relationshipsByName["predefinedPackages"])

        // Insert a new WooShippingPredefinedPackage
        let predefinedPackage = insertWooShippingPredefinedPackage(to: targetContext)
        XCTAssertEqual(try targetContext.count(entityName: "WooShippingPredefinedPackage"), 1)

        // Check all attributes and relationships
        XCTAssertNotNil(predefinedPackage.entity.attributesByName["id"])
        XCTAssertNotNil(predefinedPackage.entity.attributesByName["groupID"])
        XCTAssertNotNil(predefinedPackage.entity.attributesByName["name"])
        XCTAssertNotNil(predefinedPackage.entity.attributesByName["dimensions"])
        XCTAssertNotNil(predefinedPackage.entity.attributesByName["isLetter"])
        XCTAssertNotNil(predefinedPackage.entity.attributesByName["boxWeight"])
        XCTAssertNotNil(predefinedPackage.entity.relationshipsByName["predefinedOption"])
        XCTAssertNotNil(predefinedPackage.entity.relationshipsByName["savedPredefinedPackage"])

        // Insert a new WooShippingSavedPredefinedPackage
        let savedPredefinedPackage = insertWooShippingSavedPredefinedPackage(to: targetContext)
        XCTAssertEqual(try targetContext.count(entityName: "WooShippingSavedPredefinedPackage"), 1)

        // Check all attributes and relationships
        XCTAssertNotNil(savedPredefinedPackage.entity.attributesByName["providerID"])
        XCTAssertNotNil(savedPredefinedPackage.entity.attributesByName["groupTitle"])
        XCTAssertNotNil(savedPredefinedPackage.entity.relationshipsByName["package"])

        // Insert a new WooShippingCustomPackage
        let customPackage = insertWooShippingCustomPackage(to: targetContext)
        XCTAssertEqual(try targetContext.count(entityName: "WooShippingCustomPackage"), 1)

        // Check all attributes
        XCTAssertNotNil(customPackage.entity.attributesByName["id"])
        XCTAssertNotNil(customPackage.entity.attributesByName["name"])
        XCTAssertNotNil(customPackage.entity.attributesByName["dimensions"])
        XCTAssertNotNil(customPackage.entity.attributesByName["rawType"])
        XCTAssertNotNil(customPackage.entity.attributesByName["boxWeight"])

        // Check all relationships
        packagesResponse.setValue(NSOrderedSet(array: [carrierPredefinedOptions]), forKey: "allPredefinedOptions")
        packagesResponse.setValue(NSSet(array: [customPackage]), forKey: "customPackages")
        packagesResponse.setValue(NSSet(array: [savedPredefinedPackage]), forKey: "savedPredefinedPackages")
        carrierPredefinedOptions.setValue(NSOrderedSet(array: [predefinedOption]), forKey: "predefinedOptions")
        predefinedOption.setValue(NSSet(array: [predefinedPackage]), forKey: "predefinedPackages")
        savedPredefinedPackage.setValue(predefinedPackage, forKey: "package")
        try targetContext.save()
        XCTAssertEqual(packagesResponse.value(forKey: "allPredefinedOptions") as? NSOrderedSet, NSOrderedSet(array: [carrierPredefinedOptions]))
        XCTAssertEqual(packagesResponse.value(forKey: "customPackages") as? NSSet, NSSet(array: [customPackage]))
        XCTAssertEqual(packagesResponse.value(forKey: "savedPredefinedPackages") as? NSSet, NSSet(array: [savedPredefinedPackage]))
        XCTAssertEqual(carrierPredefinedOptions.value(forKey: "predefinedOptions") as? NSOrderedSet, NSOrderedSet(array: [predefinedOption]))
        XCTAssertEqual(predefinedOption.value(forKey: "predefinedPackages") as? NSSet, NSSet(array: [predefinedPackage]))
        XCTAssertEqual(savedPredefinedPackage.value(forKey: "package") as? WooShippingPredefinedPackage, predefinedPackage)
    }

    func test_migrating_from_119_to_120_adds_new_hasSSOEnabled_attribute_to_site() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 119")
        let sourceContext = sourceContainer.viewContext

        let site = insertSite(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(site.entity.attributesByName["hasSSOEnabled"], "Precondition. Attribute does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 120")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedSite = try XCTUnwrap(targetContext.first(entityName: "Site"))

        // `hasSSOEnabled` should be present in `migratedSite`
        XCTAssertNotNil(migratedSite.entity.attributesByName["hasSSOEnabled"])

        let savedHasSSOEnabled = try XCTUnwrap(migratedSite.value(forKey: "hasSSOEnabled") as? Bool)
        XCTAssertFalse(savedHasSSOEnabled) // default value

        migratedSite.setValue(true, forKey: "hasSSOEnabled")
        try targetContext.save()

        let updatedHasSSOEnabled = try XCTUnwrap(migratedSite.value(forKey: "hasSSOEnabled") as? Bool)
        XCTAssertTrue(updatedHasSSOEnabled)
    }

    func test_migrating_from_120_to_121_adds_new_attributes_usedDate_and_expiryDate_to_shippingLabel() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 120")
        let sourceContext = sourceContainer.viewContext

        let label = insertShippingLabel(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(label.entity.attributesByName["usedDate"], "Precondition. Attribute does not exist.")
        XCTAssertNil(label.entity.attributesByName["expiryDate"], "Precondition. Attribute does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 121")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedLabel = try XCTUnwrap(targetContext.first(entityName: "ShippingLabel"))

        // `usedDate` should be present in `migratedLabel`
        XCTAssertNotNil(migratedLabel.entity.attributesByName["usedDate"])

        // `expiryDate` should be present in `migratedLabel`
        XCTAssertNotNil(migratedLabel.entity.attributesByName["expiryDate"])

        let savedUsedDate = migratedLabel.value(forKey: "usedDate") as? Date
        XCTAssertNil(savedUsedDate) // default value

        let savedExpiryDate = migratedLabel.value(forKey: "expiryDate") as? Date
        XCTAssertNil(savedExpiryDate) // default value

        let date = Date()
        migratedLabel.setValue(date, forKey: "usedDate")
        migratedLabel.setValue(date, forKey: "expiryDate")
        try targetContext.save()

        let updatedUsedDate = migratedLabel.value(forKey: "usedDate") as? Date
        XCTAssertEqual(updatedUsedDate, date)

        let updatedExpiryDate = migratedLabel.value(forKey: "expiryDate") as? Date
        XCTAssertEqual(updatedExpiryDate, date)
    }

    func test_migrating_from_121_to_122_adds_new_attribute_shipmentID_to_shippingLabel() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 121")
        let sourceContext = sourceContainer.viewContext

        let label = insertShippingLabel(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(label.entity.attributesByName["shipmentID"], "Precondition. Attribute does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 122")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedLabel = try XCTUnwrap(targetContext.first(entityName: "ShippingLabel"))

        // `shipmentID` should be present in `migratedLabel`
        XCTAssertNotNil(migratedLabel.entity.attributesByName["shipmentID"])

        let savedShipmentID = migratedLabel.value(forKey: "shipmentID") as? String
        XCTAssertNil(savedShipmentID) // default value

        let id = "1"
        migratedLabel.setValue(id, forKey: "shipmentID")
        try targetContext.save()

        let updatedShipmentID = migratedLabel.value(forKey: "shipmentID") as? String
        XCTAssertEqual(updatedShipmentID, id)
    }

    func test_migrating_from_122_to_123_adds_new_attribute_createdVia_to_order() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 122")
        let sourceContext = sourceContainer.viewContext

        let object = sourceContext.insert(entityName: "Order", properties: [
            "orderID": 123,
            "statusKey": "" // statusKey is a required value, unrelated to this migration
        ])
        try sourceContext.save()

        // `createdVia` should not be present in model 122
        XCTAssertNil(object.entity.attributesByName["createdVia"], "Precondition. Attribute does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 123")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedObject = try XCTUnwrap(targetContext.first(entityName: "Order"))

        // `createdVia` should be present in model 123
        XCTAssertNotNil(migratedObject.entity.attributesByName["createdVia"])

        // `createdVia` value should default as nil in model 123
        let value = migratedObject.value(forKey: "createdVia") as? String
        XCTAssertNil(value)

        // `createdVia` must be settable
        migratedObject.setValue("pos-rest-api", forKey: "createdVia")
        try targetContext.save()
        let updatedValue = migratedObject.value(forKey: "createdVia") as? String
        XCTAssertEqual(updatedValue, "pos-rest-api")
    }

    func test_migrating_from_123_to_124_enables_creating_new_WooShippingShipment_and_WooShippingShipmentItem_entities() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 123")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. These entities should not exist in Model 123
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "WooShippingShipment", in: sourceContext))
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "WooShippingShipmentItem", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 124")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "WooShippingShipment"), 0)
        XCTAssertEqual(try targetContext.count(entityName: "WooShippingShipmentItem"), 0)

        let shipment = insertWooShippingShipment(to: targetContext)
        let shipmentItem = insertWooShippingShipmentItem(to: targetContext)
        shipmentItem.setValue(shipment, forKey: "shipment")
        XCTAssertNoThrow(try targetContext.save())

        XCTAssertEqual(try targetContext.count(entityName: "WooShippingShipment"), 1)
        let insertedShipment = try XCTUnwrap(targetContext.firstObject(ofType: WooShippingShipment.self))
        XCTAssertEqual(insertedShipment, shipment)
        XCTAssertEqual(insertedShipment.items?.count, 1)

        XCTAssertEqual(try targetContext.count(entityName: "WooShippingShipmentItem"), 1)
        let insertedShipmentItem = try XCTUnwrap(targetContext.firstObject(ofType: WooShippingShipmentItem.self))
        XCTAssertEqual(insertedShipmentItem, shipmentItem)
    }

    func test_migrating_from_123_to_124_adds_new_relationship_shipment_to_shippingLabel() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 123")
        let sourceContext = sourceContainer.viewContext

        let label = insertShippingLabel(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(label.entity.relationshipsByName["shipment"], "Precondition. Relationship does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 124")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedLabel = try XCTUnwrap(targetContext.first(entityName: "ShippingLabel"))

        // `shipment` should be present in `migratedLabel`
        XCTAssertNotNil(migratedLabel.entity.relationshipsByName["shipment"])

        let savedShipment = migratedLabel.value(forKey: "shipment") as? WooShippingShipment
        XCTAssertNil(savedShipment) // default value

        let shipment = insertWooShippingShipment(to: targetContext)
        migratedLabel.setValue(shipment, forKey: "shipment")
        try targetContext.save()

        let updatedShipment = migratedLabel.value(forKey: "shipment") as? WooShippingShipment
        XCTAssertEqual(updatedShipment, shipment)
    }

    func test_migrating_from_123_to_124_adds_new_relationship_shipments_to_order() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 123")
        let sourceContext = sourceContainer.viewContext

        let order = insertOrder(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(order.entity.relationshipsByName["shipments"], "Precondition. Relationship does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 124")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedOrder = try XCTUnwrap(targetContext.first(entityName: "Order"))

        // `shipments` should be present in `migratedOrder`
        XCTAssertNotNil(migratedOrder.entity.relationshipsByName["shipments"])

        let savedShipments = migratedOrder.value(forKey: "shipments") as? Set<WooShippingShipment>
        XCTAssertEqual(savedShipments?.count, 0) // default value

        let shipment = insertWooShippingShipment(to: targetContext)
        migratedOrder.mutableSetValue(forKey: "shipments").add(shipment)
        try targetContext.save()

        XCTAssertEqual(migratedOrder.value(forKey: "shipments") as? Set<NSManagedObject>, [shipment])
    }

    func test_migrating_from_123_to_124_enables_creating_new_WooShippingOriginAddress_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 123")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. WooShippingOriginAddress should not exist in Model 123
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "WooShippingOriginAddress", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 124")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "WooShippingOriginAddress"), 0)

        let address = insertWooShippingOriginAddress(to: targetContext)
        XCTAssertNoThrow(try targetContext.save())

        XCTAssertEqual(try targetContext.count(entityName: "WooShippingOriginAddress"), 1)
        let insertedAddress = try XCTUnwrap(targetContext.firstObject(ofType: WooShippingOriginAddress.self))
        XCTAssertEqual(insertedAddress, address)
    }

    func test_migrating_from_123_to_124_adds_new_attributes_lastOrderCompleted_and_addPaymentMethodURL_to_ShippingLabelAccountSettings() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 123")
        let sourceContext = sourceContainer.viewContext

        let object = sourceContext.insert(entityName: "ShippingLabelAccountSettings", properties: [
            "siteID": 123,
            "canEditSettings": false,
            "canManagePayments": false,
            "isEmailReceiptsEnabled": false,
            "lastSelectedPackageID": "",
            "paperSize": "",
            "selectedPaymentMethodID": 0,
            "storeOwnerDisplayName": "",
            "storeOwnerUsername": "",
            "storeOwnerWpcomEmail": "",
            "storeOwnerWpcomUsername": ""
        ])
        try sourceContext.save()

        // `lastOrderCompleted` and `addPaymentMethodURL` should not be present in model 122
        XCTAssertNil(object.entity.attributesByName["lastOrderCompleted"], "Precondition. Attribute does not exist.")
        XCTAssertNil(object.entity.attributesByName["addPaymentMethodURL"], "Precondition. Attribute does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 124")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedObject = try XCTUnwrap(targetContext.first(entityName: "ShippingLabelAccountSettings"))

        // `lastOrderCompleted` should be present in model 124
        XCTAssertNotNil(migratedObject.entity.attributesByName["lastOrderCompleted"])

        // `addPaymentMethodURL` value should default as nil in model 124
        let value = migratedObject.value(forKey: "addPaymentMethodURL") as? String
        XCTAssertNil(value)

        // `lastOrderCompleted` must be settable
        migratedObject.setValue(true, forKey: "lastOrderCompleted")
        try targetContext.save()
        let updatedValue = migratedObject.value(forKey: "lastOrderCompleted") as? Bool
        XCTAssertEqual(updatedValue, true)

        // `addPaymentMethodURL` must be settable
        migratedObject.setValue("https://example.com", forKey: "addPaymentMethodURL")
        try targetContext.save()
        let urlValue = migratedObject.value(forKey: "addPaymentMethodURL") as? String
        XCTAssertEqual(urlValue, "https://example.com")
    }

    func test_migrating_from_124_to_125_adds_new_attribute_hazmatCategory_to_shippingLabel() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 124")
        let sourceContext = sourceContainer.viewContext

        let label = insertShippingLabel(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(label.entity.attributesByName["hazmatCategory"], "Precondition. Attribute does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 125")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedLabel = try XCTUnwrap(targetContext.first(entityName: "ShippingLabel"))

        // `hazmatCategory` should be present in `migratedLabel`
        XCTAssertNotNil(migratedLabel.entity.attributesByName["hazmatCategory"])

        let hazmatCategory = migratedLabel.value(forKey: "hazmatCategory") as? String
        XCTAssertNil(hazmatCategory) // default value

        let category = "1"
        migratedLabel.setValue(category, forKey: "hazmatCategory")
        try targetContext.save()

        let updatedCategory = migratedLabel.value(forKey: "hazmatCategory") as? String
        XCTAssertEqual(updatedCategory, category)
    }

    func test_migrating_126_to_127_adds_new_booking_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 126")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. Booking should not exist in Model 126
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "Booking", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 127")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "Booking"), 0)

        let booking = insertBooking(to: targetContext)
        XCTAssertNoThrow(try targetContext.save())

        XCTAssertEqual(try targetContext.count(entityName: "Booking"), 1)
        let insertedBooking = try XCTUnwrap(targetContext.firstObject(ofType: Booking.self))
        XCTAssertEqual(insertedBooking, booking)
        XCTAssertEqual(insertedBooking.parentID, 0) // default value
    }

    func test_migrating_127_to_128_adds_new_bookingOrderInfo_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 127")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. BookingOrderInfo should not exist in Model 127
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "BookingOrderInfo", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 128")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "BookingOrderInfo"), 0)

        let orderInfo = insertBookingOrderInfo(to: targetContext)
        XCTAssertNoThrow(try targetContext.save())

        XCTAssertEqual(try targetContext.count(entityName: "BookingOrderInfo"), 1)
        let insertedOrderInfo = try XCTUnwrap(targetContext.first(entityName: "BookingOrderInfo"))
        XCTAssertEqual(insertedOrderInfo, orderInfo)

        // Verify customerInfo relationship exists and can be set
        XCTAssertNotNil(orderInfo.entity.relationshipsByName["customerInfo"])
        let customerInfo = insertBookingCustomerInfo(to: targetContext)
        orderInfo.setValue(customerInfo, forKey: "customerInfo")
        try targetContext.save()
        XCTAssertEqual(orderInfo.value(forKey: "customerInfo") as? NSManagedObject, customerInfo)

        // Verify productInfo relationship exists and can be set
        XCTAssertNotNil(orderInfo.entity.relationshipsByName["productInfo"])
        let productInfo = insertBookingProductInfo(to: targetContext)
        orderInfo.setValue(productInfo, forKey: "productInfo")
        try targetContext.save()
        XCTAssertEqual(orderInfo.value(forKey: "productInfo") as? NSManagedObject, productInfo)

        // Verify paymentInfo relationship exists and can be set
        XCTAssertNotNil(orderInfo.entity.relationshipsByName["paymentInfo"])
        let paymentInfo = insertBookingPaymentInfo(to: targetContext)
        orderInfo.setValue(paymentInfo, forKey: "paymentInfo")
        try targetContext.save()
        XCTAssertEqual(orderInfo.value(forKey: "paymentInfo") as? NSManagedObject, paymentInfo)

        // Verify booking relationship exists and can be set
        XCTAssertNotNil(orderInfo.entity.relationshipsByName["booking"])
        let booking = insertBooking(to: targetContext)
        orderInfo.setValue(booking, forKey: "booking")
        try targetContext.save()
        XCTAssertEqual(orderInfo.value(forKey: "booking") as? NSManagedObject, booking)
    }

    func test_migrating_127_to_128_adds_new_bookingCustomerInfo_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 127")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. BookingCustomerInfo should not exist in Model 127
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "BookingCustomerInfo", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 128")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "BookingCustomerInfo"), 0)

        let customerInfo = insertBookingCustomerInfo(to: targetContext)
        XCTAssertNoThrow(try targetContext.save())

        XCTAssertEqual(try targetContext.count(entityName: "BookingCustomerInfo"), 1)
        let insertedCustomerInfo = try XCTUnwrap(targetContext.first(entityName: "BookingCustomerInfo"))
        XCTAssertEqual(insertedCustomerInfo, customerInfo)
    }

    func test_migrating_127_to_128_adds_new_bookingProductInfo_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 127")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. BookingProductInfo should not exist in Model 127
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "BookingProductInfo", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 128")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "BookingProductInfo"), 0)

        let productInfo = insertBookingProductInfo(to: targetContext)
        XCTAssertNoThrow(try targetContext.save())

        XCTAssertEqual(try targetContext.count(entityName: "BookingProductInfo"), 1)
        let insertedProductInfo = try XCTUnwrap(targetContext.first(entityName: "BookingProductInfo"))
        XCTAssertEqual(insertedProductInfo, productInfo)
    }

    func test_migrating_127_to_128_adds_new_bookingPaymentInfo_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 127")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. BookingPaymentInfo should not exist in Model 127
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "BookingPaymentInfo", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 128")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "BookingPaymentInfo"), 0)

        let paymentInfo = insertBookingPaymentInfo(to: targetContext)
        XCTAssertNoThrow(try targetContext.save())

        XCTAssertEqual(try targetContext.count(entityName: "BookingPaymentInfo"), 1)
        let insertedPaymentInfo = try XCTUnwrap(targetContext.first(entityName: "BookingPaymentInfo"))
        XCTAssertEqual(insertedPaymentInfo, paymentInfo)
    }

    func test_migrating_127_to_128_adds_new_relationship_orderInfo_to_booking() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 127")
        let sourceContext = sourceContainer.viewContext

        let booking = insertBooking(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(booking.entity.relationshipsByName["orderInfo"], "Precondition. Relationship does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 128")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedBooking = try XCTUnwrap(targetContext.first(entityName: "Booking"))

        // `orderInfo` should be present in `migratedBooking`
        XCTAssertNotNil(migratedBooking.entity.relationshipsByName["orderInfo"])

        let savedOrderInfo = migratedBooking.value(forKey: "orderInfo") as? NSManagedObject
        XCTAssertNil(savedOrderInfo) // default value

        let orderInfo = insertBookingOrderInfo(to: targetContext)
        migratedBooking.setValue(orderInfo, forKey: "orderInfo")
        try targetContext.save()

        let updatedOrderInfo = migratedBooking.value(forKey: "orderInfo") as? NSManagedObject
        XCTAssertEqual(updatedOrderInfo, orderInfo)
    }

    func test_migrating_127_to_128_adds_new_bookingResource_entity() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 127")
        let sourceContext = sourceContainer.viewContext

        try sourceContext.save()

        // Confidence Check. BookingResource should not exist in Model 127
        XCTAssertNil(NSEntityDescription.entity(forEntityName: "BookingResource", in: sourceContext))

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 128")
        let targetContext = targetContainer.viewContext

        // Then
        XCTAssertEqual(try targetContext.count(entityName: "BookingResource"), 0)

        let resource = insertBookingResource(to: targetContext)
        XCTAssertNoThrow(try targetContext.save())

        XCTAssertEqual(try targetContext.count(entityName: "BookingResource"), 1)
        let insertedResource = try XCTUnwrap(targetContext.first(entityName: "BookingResource"))
        XCTAssertEqual(insertedResource, resource)
    }

    func test_migrating_from_128_to_129_adds_new_attendanceStatusKey_attribute_to_booking() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 128")
        let sourceContext = sourceContainer.viewContext

        let booking = insertBooking(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(booking.entity.attributesByName["attendanceStatusKey"], "Precondition. Attribute does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 129")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedBooking = try XCTUnwrap(targetContext.first(entityName: "Booking"))

        // `attendanceStatusKey` should be present in `migratedBooking`
        XCTAssertNotNil(migratedBooking.entity.attributesByName["attendanceStatusKey"])

        // `attendanceStatusKey` value should default as "" in model 129
        let value = migratedBooking.value(forKey: "attendanceStatusKey") as? String
        XCTAssertEqual(value, "")

        // `attendanceStatusKey` must be settable
        migratedBooking.setValue("checked_in", forKey: "attendanceStatusKey")
        try targetContext.save()
        let updatedValue = migratedBooking.value(forKey: "attendanceStatusKey") as? String
        XCTAssertEqual(updatedValue, "checked_in")
    }

    func test_migrating_from_129_to_130_adds_new_note_attribute_to_booking() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 129")
        let sourceContext = sourceContainer.viewContext

        let booking = insertBooking(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(booking.entity.attributesByName["note"], "Precondition. Attribute does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 130")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedBooking = try XCTUnwrap(targetContext.first(entityName: "Booking"))

        // `note` should be present in `migratedBooking`
        XCTAssertNotNil(migratedBooking.entity.attributesByName["note"])
    }

    func test_migrating_from_130_to_131_adds_note_attribute_to_bookingCustomerInfo() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 130")
        let sourceContext = sourceContainer.viewContext

        let customerInfo = insertBookingCustomerInfo(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(customerInfo.entity.attributesByName["note"], "Precondition. Attribute does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 131")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedCustomerInfo = try XCTUnwrap(targetContext.first(entityName: "BookingCustomerInfo"))

        // `note` should be present in `migratedCustomerInfo`
        XCTAssertNotNil(migratedCustomerInfo.entity.attributesByName["note"])

        let noteValue = migratedCustomerInfo.value(forKey: "note") as? String
        XCTAssertNil(noteValue)

        let updatedNote = "Customer note"
        migratedCustomerInfo.setValue(updatedNote, forKey: "note")
        try targetContext.save()

        XCTAssertEqual(migratedCustomerInfo.value(forKey: "note") as? String, updatedNote)
    }

    func test_migrating_from_131_to_132_adds_datePaid_attribute_to_bookingOrderInfo() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 131")
        let sourceContext = sourceContainer.viewContext

        let orderInfo = insertBookingOrderInfo(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(orderInfo.entity.attributesByName["datePaid"], "Precondition. Attribute does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 132")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedOrderInfo = try XCTUnwrap(targetContext.first(entityName: "BookingOrderInfo"))

        // `datePaid` should be present in `migratedOrderInfo`
        XCTAssertNotNil(migratedOrderInfo.entity.attributesByName["datePaid"])

        let datePaidValue = migratedOrderInfo.value(forKey: "datePaid") as? Date
        XCTAssertNil(datePaidValue)

        let updatedDate = Date()
        migratedOrderInfo.setValue(updatedDate, forKey: "datePaid")
        try targetContext.save()

        XCTAssertEqual(migratedOrderInfo.value(forKey: "datePaid") as? Date, updatedDate)
    }

    func test_migrating_from_131_to_132_adds_total_and_refundTotal_attributes_to_bookingOrderInfo() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 131")
        let sourceContext = sourceContainer.viewContext

        let orderInfo = insertBookingOrderInfo(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(orderInfo.entity.attributesByName["total"], "Precondition. Attribute does not exist.")
        XCTAssertNil(orderInfo.entity.attributesByName["refundTotal"], "Precondition. Attribute does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 132")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedOrderInfo = try XCTUnwrap(targetContext.first(entityName: "BookingOrderInfo"))

        XCTAssertNotNil(migratedOrderInfo.entity.attributesByName["total"])
        XCTAssertNotNil(migratedOrderInfo.entity.attributesByName["refundTotal"])

        // Defaults should be 0
        let totalValue = migratedOrderInfo.value(forKey: "total") as? NSDecimalNumber
        XCTAssertEqual(totalValue, NSDecimalNumber(string: "0"))

        let refundTotalValue = migratedOrderInfo.value(forKey: "refundTotal") as? NSDecimalNumber
        XCTAssertEqual(refundTotalValue, NSDecimalNumber(string: "0"))

        // Verify values can be updated
        let updatedTotal = NSDecimalNumber(string: "99.99")
        let updatedRefundTotal = NSDecimalNumber(string: "25.00")
        migratedOrderInfo.setValue(updatedTotal, forKey: "total")
        migratedOrderInfo.setValue(updatedRefundTotal, forKey: "refundTotal")
        try targetContext.save()

        XCTAssertEqual(migratedOrderInfo.value(forKey: "total") as? NSDecimalNumber, updatedTotal)
        XCTAssertEqual(migratedOrderInfo.value(forKey: "refundTotal") as? NSDecimalNumber, updatedRefundTotal)
    }

    func test_migrating_from_132_to_133_adds_paymentStatusMetadata_attribute_to_bookingOrderInfo() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 132")
        let sourceContext = sourceContainer.viewContext

        let orderInfo = insertBookingOrderInfo(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(orderInfo.entity.attributesByName["paymentStatusMetadata"], "Precondition. Attribute does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 133")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedOrderInfo = try XCTUnwrap(targetContext.first(entityName: "BookingOrderInfo"))

        XCTAssertNotNil(migratedOrderInfo.entity.attributesByName["paymentStatusMetadata"])

        let metadataValue = migratedOrderInfo.value(forKey: "paymentStatusMetadata") as? String
        XCTAssertNil(metadataValue)

        let updatedValue = "paid"
        migratedOrderInfo.setValue(updatedValue, forKey: "paymentStatusMetadata")
        try targetContext.save()

        XCTAssertEqual(migratedOrderInfo.value(forKey: "paymentStatusMetadata") as? String, updatedValue)
    }

    func test_migrating_from_133_to_134_adds_userID_attribute_to_Booking() throws {
        // Given
        let sourceContainer = try startPersistentContainer("Model 133")
        let sourceContext = sourceContainer.viewContext

        let booking = insertBooking(to: sourceContext)
        try sourceContext.save()

        XCTAssertNil(booking.entity.attributesByName["userID"], "Precondition. Attribute does not exist.")

        // When
        let targetContainer = try migrate(sourceContainer, to: "Model 134")

        // Then
        let targetContext = targetContainer.viewContext
        let migratedBooking = try XCTUnwrap(targetContext.first(entityName: "Booking"))

        XCTAssertNotNil(migratedBooking.entity.attributesByName["userID"])

        // Default value should be 0
        let defaultValue = migratedBooking.value(forKey: "userID") as? Int64
        XCTAssertEqual(defaultValue, 0)

        // Verify new attribute can be set and saved
        let newUserID: Int64 = 42
        migratedBooking.setValue(newUserID, forKey: "userID")
        try targetContext.save()

        XCTAssertEqual(migratedBooking.value(forKey: "userID") as? Int64, newUserID)
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

    @discardableResult
    func insertWooShippingPackagesResponse(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "WooShippingPackagesResponse", properties: [
            "siteID": 1,
        ])
    }

    @discardableResult
    func insertWooShippingCarrierPredefinedOptions(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "WooShippingCarrierPredefinedOptions", properties: [
            "carrierID": "usps",
        ])
    }

    @discardableResult
    func insertWooShippingCustomPackage(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "WooShippingCustomPackage", properties: [
            "id": "abc123",
            "name": "Custom Box",
            "dimensions": "12.0 x 12.0 x 12.0",
            "rawType": "box",
            "boxWeight": 1.0,
        ])
    }

    @discardableResult
    func insertWooShippingPredefinedOption(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "WooShippingPredefinedOption", properties: [
            "providerID": "usps",
            "title": "USPS Priority Mail Boxes"
        ])
    }

    @discardableResult
    func insertWooShippingPredefinedPackage(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "WooShippingPredefinedPackage", properties: [
            "id": "usps",
            "groupID": "pri_flat_boxes",
            "name": "Small Flat Rate Box",
            "dimensions": "8.63 x 5.38 x 1.63",
            "isLetter": false,
            "boxWeight": "0",
        ])
    }

    @discardableResult
    func insertWooShippingSavedPredefinedPackage(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "WooShippingSavedPredefinedPackage", properties: [
            "providerID": "usps",
            "groupTitle": "USPS Priority Mail Flat Rate Boxes",
        ])
    }

    @discardableResult
    func insertWooShippingShipment(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "WooShippingShipment", properties: [
            "siteID": 1,
            "orderID": 2,
            "index": "3"
        ])
    }

    @discardableResult
    func insertWooShippingShipmentItem(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "WooShippingShipmentItem", properties: [
            "id": 4,
            "subItems": ["sub_1", "sub_2"]
        ])
    }

    @discardableResult
    func insertWooShippingOriginAddress(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "WooShippingOriginAddress", properties: [
            "siteID": 1,
            "id": "test-address"
        ])
    }

    @discardableResult
    func insertBooking(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "Booking", properties: [
            "siteID": 1,
            "bookingID": 23
        ])
    }

    @discardableResult
    func insertBookingOrderInfo(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "BookingOrderInfo", properties: [
            "statusKey": "completed"
        ])
    }

    @discardableResult
    func insertBookingCustomerInfo(to context: NSManagedObjectContext) -> NSManagedObject {
        var properties: [String: Any] = [
            "billingFirstName": "John",
            "billingLastName": "Doe",
            "billingEmail": "john.doe@example.com",
            "billingAddress1": "123 Main St",
            "billingCity": "San Francisco",
            "billingState": "CA",
            "billingPostcode": "94102",
            "billingCountry": "US"
        ]
        if let entity = NSEntityDescription.entity(forEntityName: "BookingCustomerInfo", in: context),
           entity.attributesByName.keys.contains("note") {
            properties["note"] = "Sample note"
        }
        return context.insert(entityName: "BookingCustomerInfo", properties: properties)
    }

    @discardableResult
    func insertBookingProductInfo(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "BookingProductInfo", properties: [
            "name": "Sample Product"
        ])
    }

    @discardableResult
    func insertBookingPaymentInfo(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "BookingPaymentInfo", properties: [
            "paymentMethodID": "credit_card",
            "paymentMethodTitle": "Credit Card",
            "subtotal": "100.00",
            "subtotalTax": "10.00",
            "total": "110.00",
            "totalTax": "10.00"
        ])
    }

    @discardableResult
    func insertBookingResource(to context: NSManagedObjectContext) -> NSManagedObject {
        context.insert(entityName: "BookingResource", properties: [
            "siteID": 1,
            "resourceID": 22,
            "name": "Joel (Sample resource)",
            "quantity": 1
        ])
    }
}
