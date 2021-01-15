import XCTest

@testable import Storage

class StorageTypeExtensionsTests: XCTestCase {

    private let sampleSiteID: Int64 = 98765

    private var storageManager: StorageManagerType!

    private var storage: StorageType! {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
    }

    override func tearDown() {
        storageManager.reset()
        storageManager = nil
        super.tearDown()
    }

    func test_loadAccount_by_ID() throws {
        // Given
        let account = storage.insertNewObject(ofType: Account.self)
        let userID: Int64 = 123
        account.userID = userID

        // When
        let storedAccount = try XCTUnwrap(storage.loadAccount(userID: userID))

        // Then
        XCTAssertEqual(account, storedAccount)

    }

    func test_loadAccountSettings_by_user_ID() throws {
        // Given
        let accountSettings = storage.insertNewObject(ofType: AccountSettings.self)
        let userID: Int64 = 123
        accountSettings.userID = userID

        // When
        let storedAccountSettings = try XCTUnwrap(storage.loadAccountSettings(userID: userID))

        // Then
        XCTAssertEqual(accountSettings, storedAccountSettings)
    }

    func test_loadSite_by_ID() throws {
        // Given
        let site = storage.insertNewObject(ofType: Site.self)
        let id: Int64 = 123
        site.siteID = id

        // When
        let storedSite = try XCTUnwrap(storage.loadSite(siteID: id))

        // Then
        XCTAssertEqual(site, storedSite)
    }

    func test_loadOrder_by_siteID_and_orderID() throws {
        // Given
        let orderID: Int64 = 123
        let order = storage.insertNewObject(ofType: Order.self)
        order.siteID = sampleSiteID
        order.orderID = orderID

        // When
        let storedOrder = try XCTUnwrap(storage.loadOrder(siteID: sampleSiteID, orderID: orderID))

        // Then
        XCTAssertEqual(order, storedOrder)
    }

    func test_loadOrderSearchResults_by_keyword() throws {
        // Given
        let keyword = "some-keyword"
        let searchResult = storage.insertNewObject(ofType: OrderSearchResults.self)
        searchResult.keyword = keyword

        // When
        let storedSearchResult = try XCTUnwrap(storage.loadOrderSearchResults(keyword: keyword))

        // Then
        XCTAssertEqual(searchResult, storedSearchResult)
    }

    func test_loadOrderItem_by_siteID_orderID_itemID() throws {
        // Given
        let orderID: Int64 = 123
        let itemID: Int64 = 1234
        let orderItem = storage.insertNewObject(ofType: OrderItem.self)
        orderItem.itemID = itemID

        let order = storage.insertNewObject(ofType: Order.self)
        order.siteID = sampleSiteID
        order.orderID = orderID
        order.addToItems(orderItem)

        // When
        let storedOrderItem = try XCTUnwrap(storage.loadOrderItem(siteID: sampleSiteID, orderID: orderID, itemID: itemID))

        // Then
        XCTAssertEqual(orderItem, storedOrderItem)
    }

    func test_loadOrderItemTax_by_itemID_taxID() throws {
        // Given
        let itemID: Int64 = 123
        let taxID: Int64 = 1234
        let orderItemTax = storage.insertNewObject(ofType: OrderItemTax.self)
        orderItemTax.taxID = taxID

        let orderItem = storage.insertNewObject(ofType: OrderItem.self)
        orderItem.itemID = itemID
        orderItem.addToTaxes(orderItemTax)

        // When
        let storedItemTax = try XCTUnwrap(storage.loadOrderItemTax(itemID: itemID, taxID: taxID))

        // Then
        XCTAssertEqual(orderItemTax, storedItemTax)
    }

    func test_loadOrderCoupon_by_siteID_couponID() throws {
        // Given
        let couponID: Int64 = 123
        let coupon = storage.insertNewObject(ofType: OrderCoupon.self)
        coupon.couponID = couponID

        let order = storage.insertNewObject(ofType: Order.self)
        order.siteID = sampleSiteID
        order.addToCoupons(coupon)

        // When
        let storedCoupon = try XCTUnwrap(storage.loadOrderCoupon(siteID: sampleSiteID, couponID: couponID))

        // Then
        XCTAssertEqual(coupon, storedCoupon)
    }

    func test_loadOrderFeeLine_by_siteID_feeID() throws {
        // Given
        let feeID: Int64 = 123
        let feeLine = storage.insertNewObject(ofType: OrderFeeLine.self)
        feeLine.feeID = feeID

        let order = storage.insertNewObject(ofType: Order.self)
        order.siteID = sampleSiteID
        order.addToFees(feeLine)

        // When
        let storedFeeLine = try XCTUnwrap(storage.loadOrderFeeLine(siteID: sampleSiteID, feeID: feeID))

        // Then
        XCTAssertEqual(feeLine, storedFeeLine)
    }

    func test_loadOrderRefundCondensed_by_siteID_refundID() throws {
        // Given
        let refundID: Int64 = 123
        let orderRefund = storage.insertNewObject(ofType: OrderRefundCondensed.self)
        orderRefund.refundID = refundID

        let order = storage.insertNewObject(ofType: Order.self)
        order.siteID = sampleSiteID
        order.addToRefunds(orderRefund)

        // When
        let storedOrderRefund = try XCTUnwrap(storage.loadOrderRefundCondensed(siteID: sampleSiteID, refundID: refundID))

        // Then
        XCTAssertEqual(orderRefund, storedOrderRefund)
    }

    func test_loadOrderShippingLine_by_siteID_shippingID() throws {
        // Given
        let shippingID: Int64 = 123
        let shippingLine = storage.insertNewObject(ofType: ShippingLine.self)
        shippingLine.shippingID = shippingID

        let order = storage.insertNewObject(ofType: Order.self)
        order.siteID = sampleSiteID
        order.addToShippingLines(shippingLine)

        // When
        let storedShippingLine = try XCTUnwrap(storage.loadOrderShippingLine(siteID: sampleSiteID, shippingID: shippingID))

        // Then
        XCTAssertEqual(shippingLine, storedShippingLine)
    }

    func test_loadOrderNote_by_noteID() throws {
        // Given
        let noteID: Int64 = 123
        let orderNote = storage.insertNewObject(ofType: OrderNote.self)
        orderNote.noteID = noteID

        // When
        let storedNote = try XCTUnwrap(storage.loadOrderNote(noteID: noteID))

        // Then
        XCTAssertEqual(orderNote, storedNote)
    }

    func test_loadOrderCount_by_siteID() throws {
        // Given
        let orderCount = storage.insertNewObject(ofType: OrderCount.self)
        orderCount.siteID = sampleSiteID

        // When
        let storedOrderCount = try XCTUnwrap(storage.loadOrderCount(siteID: sampleSiteID))

        // Then
        XCTAssertEqual(orderCount, storedOrderCount)
    }

    func test_loadTopEarnerStats_by_date_granularity() throws {
        // Given
        let date = Date().description
        let granularity = "daily"
        let topEarnerStat = storage.insertNewObject(ofType: TopEarnerStats.self)
        topEarnerStat.date = date
        topEarnerStat.granularity = granularity

        // When
        let storedTopEarnerStat = try XCTUnwrap(storage.loadTopEarnerStats(date: date, granularity: granularity))

        // Then
        XCTAssertEqual(topEarnerStat, storedTopEarnerStat)
    }

    func test_loadSiteVisitStats_by_granularity() throws {
        // Given
        let granularity = "daily"
        let siteVisitStat = storage.insertNewObject(ofType: SiteVisitStats.self)
        siteVisitStat.granularity = granularity

        // When
        let storedSiteVisitStat = try XCTUnwrap(storage.loadSiteVisitStats(granularity: granularity))

        // Then
        XCTAssertEqual(siteVisitStat, storedSiteVisitStat)
    }

    func test_loadSiteVisitStats_by_granularity_date() throws {
        // Given
        let date = Date().description
        let granularity = "daily"
        let siteVisitStat = storage.insertNewObject(ofType: SiteVisitStats.self)
        siteVisitStat.date = date
        siteVisitStat.granularity = granularity

        // When
        let storedSiteVisitStat = try XCTUnwrap(storage.loadSiteVisitStats(granularity: granularity, date: date))

        // Then
        XCTAssertEqual(siteVisitStat, storedSiteVisitStat)
    }

    func test_loadOrderStatsV4_by_siteID_timeRange() throws {
        // Given
        let timeRange = "Daily"
        let statsV4 = storage.insertNewObject(ofType: OrderStatsV4.self)
        statsV4.siteID = sampleSiteID
        statsV4.timeRange = timeRange

        // When
        let storedStatsV4 = try XCTUnwrap(storage.loadOrderStatsV4(siteID: sampleSiteID, timeRange: timeRange))

        // Then
        XCTAssertEqual(statsV4, storedStatsV4)
    }

    func test_loadOrderStatsV4_by_interval_orderStats() throws {
        // Given
        let interval = "24-31"
        let orderStats = storage.insertNewObject(ofType: OrderStatsV4.self)
        let statsInterval = storage.insertNewObject(ofType: OrderStatsV4Interval.self)
        statsInterval.interval = interval
        statsInterval.stats = orderStats

        // When
        let storedStatsInterval = try XCTUnwrap(storage.loadOrderStatsInterval(interval: interval, orderStats: orderStats))

        // Then
        XCTAssertEqual(statsInterval, storedStatsInterval)
    }

    func test_loadOrderStatuses_by_siteID() throws {
        // Given
        let status1 = storage.insertNewObject(ofType: OrderStatus.self)
        status1.siteID = sampleSiteID

        let status2 = storage.insertNewObject(ofType: OrderStatus.self)
        status2.siteID = sampleSiteID

        // When
        let storedStatuses = try XCTUnwrap(storage.loadOrderStatuses(siteID: sampleSiteID))

        // Then
        XCTAssertEqual(Set([status1, status2]), Set(storedStatuses))
    }

    func test_loadOrderStatus_by_siteID_slug() throws {
        // Given
        let slug = "slug"
        let status = storage.insertNewObject(ofType: OrderStatus.self)
        status.siteID = sampleSiteID
        status.slug = slug

        // When
        let storedStatus = try XCTUnwrap(storage.loadOrderStatus(siteID: sampleSiteID, slug: slug))

        // Then
        XCTAssertEqual(status, storedStatus)
    }

    func test_loadAllSiteSettings_by_siteID() throws {
        // Given
        let siteSetting1 = storage.insertNewObject(ofType: SiteSetting.self)
        siteSetting1.siteID = sampleSiteID

        let siteSetting2 = storage.insertNewObject(ofType: SiteSetting.self)
        siteSetting2.siteID = sampleSiteID

        // When
        let storedSiteSettings = try XCTUnwrap(storage.loadAllSiteSettings(siteID: sampleSiteID))

        // Then
        XCTAssertEqual(Set([siteSetting1, siteSetting2]), Set(storedSiteSettings))
    }

    func test_loadAllSiteSettings_by_siteID_groupKey() throws {
        // Given
        let groupKey = "group"
        let siteSetting1 = storage.insertNewObject(ofType: SiteSetting.self)
        siteSetting1.siteID = sampleSiteID
        siteSetting1.settingGroupKey = groupKey

        let siteSetting2 = storage.insertNewObject(ofType: SiteSetting.self)
        siteSetting2.siteID = sampleSiteID
        siteSetting2.settingGroupKey = groupKey

        // When
        let storedSiteSettings = try XCTUnwrap(storage.loadSiteSettings(siteID: sampleSiteID, settingGroupKey: groupKey))

        // Then
        XCTAssertEqual(Set([siteSetting1, siteSetting2]), Set(storedSiteSettings))
    }

    func test_loadSiteSettings_by_siteID_settingID() throws {
        // Given
        let settingID = "123"
        let siteSetting = storage.insertNewObject(ofType: SiteSetting.self)
        siteSetting.siteID = sampleSiteID
        siteSetting.settingID = settingID

        // When
        let storedSiteSetting = try XCTUnwrap(storage.loadSiteSetting(siteID: sampleSiteID, settingID: settingID))

        // Then
        XCTAssertEqual(siteSetting, storedSiteSetting)
    }

    func test_loadNotification_by_noteID() throws {
        // Given
        let noteID: Int64 = 123
        let notification = storage.insertNewObject(ofType: Note.self)
        notification.noteID = noteID

        // When
        let storedNotification = try XCTUnwrap(storage.loadNotification(noteID: noteID))

        // Then
        XCTAssertEqual(notification, storedNotification)
    }

    func test_loadNotification_by_noteID_noteHash() throws {
        // Given
        let noteID: Int64 = 123
        let noteHash: Int64 = 1234
        let notification = storage.insertNewObject(ofType: Note.self)
        notification.noteID = noteID
        notification.noteHash = noteHash

        // When
        let storedNotification = try XCTUnwrap(storage.loadNotification(noteID: noteID, noteHash: (Int)(noteHash)))

        // Then
        XCTAssertEqual(notification, storedNotification)
    }

    func test_loadShipmentTracking_by_siteID_orderID_trackingID() throws {
        // Given
        let orderID: Int64 = 123
        let trackingID = "1234"
        let shipmentTracking = storage.insertNewObject(ofType: ShipmentTracking.self)
        shipmentTracking.siteID = sampleSiteID
        shipmentTracking.orderID = orderID
        shipmentTracking.trackingID = trackingID

        // When
        let storedShipmentTracking = try XCTUnwrap(storage.loadShipmentTracking(siteID: sampleSiteID, orderID: orderID, trackingID: trackingID))

        // Then
        XCTAssertEqual(shipmentTracking, storedShipmentTracking)
    }

    func test_loadShipmentTrackingList_by_siteID_orderID() throws {
        // Given
        let orderID: Int64 = 123
        let shipmentTracking1 = storage.insertNewObject(ofType: ShipmentTracking.self)
        shipmentTracking1.siteID = sampleSiteID
        shipmentTracking1.orderID = orderID

        let shipmentTracking2 = storage.insertNewObject(ofType: ShipmentTracking.self)
        shipmentTracking2.siteID = sampleSiteID
        shipmentTracking2.orderID = orderID

        // When
        let storedTrackingList = try XCTUnwrap(storage.loadShipmentTrackingList(siteID: sampleSiteID, orderID: orderID))

        // Then
        XCTAssertEqual(Set([shipmentTracking1, shipmentTracking2]), Set(storedTrackingList))
    }

    func test_loadShipmentTrackingProviderGroup_by_siteID_groupName() throws {
        // Given
        let providerGroup = "group"
        let shipmentProviderGroup = storage.insertNewObject(ofType: ShipmentTrackingProviderGroup.self)
        shipmentProviderGroup.siteID = sampleSiteID
        shipmentProviderGroup.name = providerGroup

        // When
        let storedShipmentProviderGroup = try XCTUnwrap(storage.loadShipmentTrackingProviderGroup(siteID: sampleSiteID, providerGroupName: providerGroup))

        // Then
        XCTAssertEqual(shipmentProviderGroup, storedShipmentProviderGroup)
    }

    func test_loadShipmentTrackingProviderGroupList_by_siteID() throws {
        // Given
        let shipmentProviderGroup1 = storage.insertNewObject(ofType: ShipmentTrackingProviderGroup.self)
        shipmentProviderGroup1.siteID = sampleSiteID

        let shipmentProviderGroup2 = storage.insertNewObject(ofType: ShipmentTrackingProviderGroup.self)
        shipmentProviderGroup2.siteID = sampleSiteID

        // When
        let storedShipmentProviderGroup = try XCTUnwrap(storage.loadShipmentTrackingProviderGroupList(siteID: sampleSiteID))

        // Then
        XCTAssertEqual(Set([shipmentProviderGroup1, shipmentProviderGroup2]), Set(storedShipmentProviderGroup))
    }

    func test_loadShipmentTrackingProvider_by_siteID_name() throws {
        // Given
        let name = "name"
        let trackingProvider = storage.insertNewObject(ofType: ShipmentTrackingProvider.self)
        trackingProvider.siteID = sampleSiteID
        trackingProvider.name = name

        // When
        let storedTrackingProvider = try XCTUnwrap(storage.loadShipmentTrackingProvider(siteID: sampleSiteID, name: name))

        // Then
        XCTAssertEqual(trackingProvider, storedTrackingProvider)
    }

    func test_loadShipmentTrackingProviderList_by_siteID() throws {
        // Given
        let trackingProvider1 = storage.insertNewObject(ofType: ShipmentTrackingProvider.self)
        trackingProvider1.siteID = sampleSiteID

        let trackingProvider2 = storage.insertNewObject(ofType: ShipmentTrackingProvider.self)
        trackingProvider2.siteID = sampleSiteID

        // When
        let storedTrackingProvider = try XCTUnwrap(storage.loadShipmentTrackingProviderList(siteID: sampleSiteID))

        // Then
        XCTAssertEqual(Set([trackingProvider1, trackingProvider2]), Set(storedTrackingProvider))
    }

    func test_loadProducts_by_siteID() throws {
        // Given
        let product1 = storage.insertNewObject(ofType: Product.self)
        product1.siteID = sampleSiteID

        let product2 = storage.insertNewObject(ofType: Product.self)
        product2.siteID = sampleSiteID

        // When
        let storedProducts = try XCTUnwrap(storage.loadProducts(siteID: sampleSiteID))

        // Then
        XCTAssertEqual(Set([product2, product1]), Set(storedProducts))
    }

    func test_loadProducts_by_siteID_productIDs() throws {
        // Given
        let product1 = storage.insertNewObject(ofType: Product.self)
        product1.siteID = sampleSiteID
        product1.productID = 1

        let product2 = storage.insertNewObject(ofType: Product.self)
        product2.siteID = sampleSiteID
        product2.productID = 2

        // When
        let storedProducts = try XCTUnwrap(storage.loadProducts(siteID: sampleSiteID, productsIDs: [1, 2]))

        // Then
        XCTAssertEqual(Set([product1, product2]), Set(storedProducts))
    }

    func test_loadProduct_by_siteID_productID() throws {
        // Given
        let productID: Int64 = 123
        let product = storage.insertNewObject(ofType: Product.self)
        product.siteID = sampleSiteID
        product.productID = productID

        // When
        let storedProducts = try XCTUnwrap(storage.loadProduct(siteID: sampleSiteID, productID: productID))

        // Then
        XCTAssertEqual(product, storedProducts)
    }

    func test_loadProductAttribute_by_siteID_productID_attributeID_name() throws {
        // Given
        let productID: Int64 = 123
        let attributeID: Int64 = 1234
        let name = "name"
        let productAttribute = storage.insertNewObject(ofType: ProductAttribute.self)
        productAttribute.attributeID = attributeID
        productAttribute.name = name

        let product = storage.insertNewObject(ofType: Product.self)
        product.siteID = sampleSiteID
        product.productID = productID
        product.addToAttributes(productAttribute)

        // When
        let storedProductAttribute = try XCTUnwrap(storage.loadProductAttribute(siteID: sampleSiteID,
                                                                                productID: productID,
                                                                                attributeID: attributeID,
                                                                                name: name))

        // Then
        XCTAssertEqual(productAttribute, storedProductAttribute)
    }

    func test_loadProductAttribute_by_siteID_attributeID() throws {
        // Given
        let attributeID: Int64 = 1234
        let productAttribute = storage.insertNewObject(ofType: ProductAttribute.self)
        productAttribute.siteID = sampleSiteID
        productAttribute.attributeID = attributeID

        // When
        let storedProductAttribute = try XCTUnwrap(storage.loadProductAttribute(siteID: sampleSiteID, attributeID: attributeID))

        // Then
        XCTAssertEqual(productAttribute, storedProductAttribute)
    }

    func test_loadProductAttribute_by_siteID() throws {
        // Given
        let productAttribute1 = storage.insertNewObject(ofType: ProductAttribute.self)
        productAttribute1.siteID = sampleSiteID

        let productAttribute2 = storage.insertNewObject(ofType: ProductAttribute.self)
        productAttribute2.siteID = sampleSiteID

        // When
        let storedProductAttribute = try XCTUnwrap(storage.loadProductAttributes(siteID: sampleSiteID))

        // Then
        XCTAssertEqual(Set([productAttribute1, productAttribute2]), Set(storedProductAttribute))
    }

    func test_loadProductAttributeTerm_by_siteID_termID_attributeID() throws {
        // Given
        let termID: Int64 = 123
        let attributeID: Int64 = 1234
        let term = storage.insertNewObject(ofType: ProductAttributeTerm.self)
        term.termID = termID
        term.siteID = sampleSiteID

        let attribute = storage.insertNewObject(ofType: ProductAttribute.self)
        attribute.attributeID = attributeID
        attribute.addToTerms(term)

        // When
        let storedTerm = try XCTUnwrap(storage.loadProductAttributeTerm(siteID: sampleSiteID, termID: termID, attributeID: attributeID))

        // Then
        XCTAssertEqual(term, storedTerm)
    }

    func test_loadProductDefaultAttribute_by_siteID_productID_defaultAttributeID_name() throws {
        // Given
        let productID: Int64 = 123
        let attributeID: Int64 = 1234
        let name = "name"
        let productAttribute = storage.insertNewObject(ofType: ProductDefaultAttribute.self)
        productAttribute.attributeID = attributeID
        productAttribute.name = name

        let product = storage.insertNewObject(ofType: Product.self)
        product.siteID = sampleSiteID
        product.productID = productID
        product.addToDefaultAttributes(productAttribute)

        // When
        let storedProductAttribute = try XCTUnwrap(storage.loadProductDefaultAttribute(siteID: sampleSiteID,
                                                                                       productID: productID,
                                                                                       defaultAttributeID: attributeID,
                                                                                       name: name))

        // Then
        XCTAssertEqual(productAttribute, storedProductAttribute)
    }

    func test_loadProductImage_by_siteID_productID_imageID() throws {
        // Given
        let productID: Int64 = 123
        let imageID: Int64 = 1234
        let productImage = storage.insertNewObject(ofType: ProductImage.self)
        productImage.imageID = imageID

        let product = storage.insertNewObject(ofType: Product.self)
        product.siteID = sampleSiteID
        product.productID = productID
        product.addToImages(productImage)

        // When
        let storedProductImage = try XCTUnwrap(storage.loadProductImage(siteID: sampleSiteID, productID: productID, imageID: imageID))

        // Then
        XCTAssertEqual(productImage, storedProductImage)
    }

    func test_loadProductCategories_by_siteID() throws {
        // Given
        let category1 = storage.insertNewObject(ofType: ProductCategory.self)
        category1.siteID = sampleSiteID

        let category2 = storage.insertNewObject(ofType: ProductCategory.self)
        category2.siteID = sampleSiteID

        // When
        let storedCategories = try XCTUnwrap(storage.loadProductCategories(siteID: sampleSiteID))

        // Then
        XCTAssertEqual(Set([category1, category2]), Set(storedCategories))
    }

    func test_loadProductCategory_by_siteID_categoryID() throws {
        // Given
        let categoryID: Int64 = 123
        let category = storage.insertNewObject(ofType: ProductCategory.self)
        category.siteID = sampleSiteID
        category.categoryID = categoryID

        // When
        let storedCategory = try XCTUnwrap(storage.loadProductCategory(siteID: sampleSiteID, categoryID: categoryID))

        // Then
        XCTAssertEqual(category, storedCategory)
    }

    func test_loadProductSearchResult_by_keyboard() throws {
        // Given
        let keyword = "Keyword"
        let searchResult = storage.insertNewObject(ofType: ProductSearchResults.self)
        searchResult.keyword = keyword

        // When
        let storedSearchResult = try XCTUnwrap(storage.loadProductSearchResults(keyword: keyword))

        // Then
        XCTAssertEqual(searchResult, storedSearchResult)
    }

    func test_loadProductTag_by_siteID_tagID() throws {
        // Given
        let tagID: Int64 = 123
        let productTag = storage.insertNewObject(ofType: ProductTag.self)
        productTag.siteID = sampleSiteID
        productTag.tagID = tagID

        // When
        let storedProductTag = try XCTUnwrap(storage.loadProductTag(siteID: sampleSiteID, tagID: tagID))

        // Then
        XCTAssertEqual(productTag, storedProductTag)
    }

    func test_loadProductTags_by_siteID() throws {
        // Given
        let productTag1 = storage.insertNewObject(ofType: ProductTag.self)
        productTag1.siteID = sampleSiteID

        let productTag2 = storage.insertNewObject(ofType: ProductTag.self)
        productTag2.siteID = sampleSiteID

        // When
        let storedProductTags = try XCTUnwrap(storage.loadProductTags(siteID: sampleSiteID))

        // Then
        XCTAssertEqual(Set([productTag1, productTag2]), Set(storedProductTags))
    }

    func test_loadProductReviews_by_siteID() throws {
        // Given
        let productReview1 = storage.insertNewObject(ofType: ProductReview.self)
        productReview1.siteID = sampleSiteID

        let productReview2 = storage.insertNewObject(ofType: ProductReview.self)
        productReview2.siteID = sampleSiteID

        // When
        let storedProductReviews = try XCTUnwrap(storage.loadProductReviews(siteID: sampleSiteID))

        // Then
        XCTAssertEqual(Set([productReview1, productReview2]), Set(storedProductReviews))
    }

    func test_loadProductReviews_by_siteID_reviewID() throws {
        // Given
        let reviewID: Int64 = 123
        let productReview = storage.insertNewObject(ofType: ProductReview.self)
        productReview.siteID = sampleSiteID
        productReview.reviewID = reviewID

        // When
        let storedProductReview = try XCTUnwrap(storage.loadProductReview(siteID: sampleSiteID, reviewID: reviewID))

        // Then
        XCTAssertEqual(productReview, storedProductReview)
    }

    func test_loadProductShippingClasses_by_siteID() throws {
        // Given
        let shippingClass1 = storage.insertNewObject(ofType: ProductShippingClass.self)
        shippingClass1.siteID = sampleSiteID

        let shippingClass2 = storage.insertNewObject(ofType: ProductShippingClass.self)
        shippingClass2.siteID = sampleSiteID

        // When
        let storedShippingClasses = try XCTUnwrap(storage.loadProductShippingClasses(siteID: sampleSiteID))

        // Then
        XCTAssertEqual(Set([shippingClass1, shippingClass2]), Set(storedShippingClasses))
    }

    func test_loadProductShippingClass_by_siteID_classID() throws {
        // Given
        let classID: Int64 = 123
        let shippingClass = storage.insertNewObject(ofType: ProductShippingClass.self)
        shippingClass.siteID = sampleSiteID
        shippingClass.shippingClassID = classID

        // When
        let storedShippingClass = try XCTUnwrap(storage.loadProductShippingClass(siteID: sampleSiteID, remoteID: classID))

        // Then
        XCTAssertEqual(shippingClass, storedShippingClass)
    }

    func test_loadProductVariations_by_siteID_productID() throws {
        // Given
        let productID: Int64 = 123
        let variation1 = storage.insertNewObject(ofType: ProductVariation.self)
        variation1.siteID = sampleSiteID
        variation1.productID = productID

        let variation2 = storage.insertNewObject(ofType: ProductVariation.self)
        variation2.siteID = sampleSiteID
        variation2.productID = productID

        // When
        let storedVariations = try XCTUnwrap(storage.loadProductVariations(siteID: sampleSiteID, productID: productID))

        // Then
        XCTAssertEqual(Set([variation1, variation2]), Set(storedVariations))
    }

    func test_loadProductVariation_by_siteID_variationID() throws {
        // Given
        let variationID: Int64 = 123
        let variation = storage.insertNewObject(ofType: ProductVariation.self)
        variation.siteID = sampleSiteID
        variation.productVariationID = variationID

        // When
        let storedVariation = try XCTUnwrap(storage.loadProductVariation(siteID: sampleSiteID, productVariationID: variationID))

        // Then
        XCTAssertEqual(variation, storedVariation)
    }

    func test_loadTaxClass_by_slug() throws {
        // Given
        let slug = "slug"
        let taxClass = storage.insertNewObject(ofType: TaxClass.self)
        taxClass.slug = slug

        // When
        let storedTaxClass = try XCTUnwrap(storage.loadTaxClass(slug: slug))

        // Then
        XCTAssertEqual(taxClass, storedTaxClass)
    }

    func test_loadRefunds_by_siteID_orderID() throws {
        // Given
        let orderID: Int64 = 123
        let refund1 = storage.insertNewObject(ofType: Refund.self)
        refund1.siteID = sampleSiteID
        refund1.orderID = orderID

        let refund2 = storage.insertNewObject(ofType: Refund.self)
        refund2.siteID = sampleSiteID
        refund2.orderID = orderID

        // When
        let storedRefunds = try XCTUnwrap(storage.loadRefunds(siteID: sampleSiteID, orderID: orderID))

        // Then
        XCTAssertEqual(Set([refund1, refund2]), Set(storedRefunds))
    }

    func test_loadRefund_by_siteID_orderID_refundID() throws {
        // Given
        let orderID: Int64 = 123
        let refundID: Int64 = 1234
        let refund = storage.insertNewObject(ofType: Refund.self)
        refund.siteID = sampleSiteID
        refund.orderID = orderID
        refund.refundID = refundID

        // When
        let storedRefund = try XCTUnwrap(storage.loadRefund(siteID: sampleSiteID, orderID: orderID, refundID: refundID))

        // Then
        XCTAssertEqual(refund, storedRefund)
    }

    func test_loadRefundItem_by_siteID_refundID_itemID() throws {
        // Given
        let refundID: Int64 = 123
        let itemID: Int64 = 1234
        let refundItem = storage.insertNewObject(ofType: OrderItemRefund.self)
        refundItem.itemID = itemID

        let refund = storage.insertNewObject(ofType: Refund.self)
        refund.siteID = sampleSiteID
        refund.refundID = refundID
        refund.addToItems(refundItem)

        // When
        let storedRefundItem = try XCTUnwrap(storage.loadRefundItem(siteID: sampleSiteID, refundID: refundID, itemID: itemID))

        // Then
        XCTAssertEqual(refundItem, storedRefundItem)
    }

    func test_loadRefundShippingLine_by_siteID_shippingID() throws {
        // Given
        let shippingID: Int64 = 123
        let shippingLine = storage.insertNewObject(ofType: ShippingLine.self)
        shippingLine.shippingID = shippingID

        let refund = storage.insertNewObject(ofType: Refund.self)
        refund.siteID = sampleSiteID
        refund.addToShippingLines(shippingLine)

        // When
        let storedShippingLine = try XCTUnwrap(storage.loadRefundShippingLine(siteID: sampleSiteID, shippingID: shippingID))

        // Then
        XCTAssertEqual(shippingLine, storedShippingLine)
    }

    func test_loadRefundItemTax_by_itemID_taxID() throws {
        // Given
        let itemID: Int64 = 123
        let taxID: Int64 = 1234
        let itemTax = storage.insertNewObject(ofType: OrderItemTaxRefund.self)
        itemTax.taxID = taxID

        let refundItem = storage.insertNewObject(ofType: OrderItemRefund.self)
        refundItem.itemID = itemID
        refundItem.addToTaxes(itemTax)

        // When
        let storedItemTax = try XCTUnwrap(storage.loadRefundItemTax(itemID: itemID, taxID: taxID))

        // Then
        XCTAssertEqual(itemTax, storedItemTax)
    }

    func test_loadAllPaymentGateways_by_siteID() throws {
        // Given
        let gateway1 = storage.insertNewObject(ofType: PaymentGateway.self)
        gateway1.siteID = sampleSiteID

        let gateway2 = storage.insertNewObject(ofType: PaymentGateway.self)
        gateway2.siteID = sampleSiteID

        // When
        let storedGateways = try XCTUnwrap(storage.loadAllPaymentGateways(siteID: sampleSiteID))

        // Then
        XCTAssertEqual(Set([gateway1, gateway2]), Set(storedGateways))
    }

    func test_loadPaymentGateway_by_siteID_gatewayID() throws {
        // Given
        let gatewayID = "gateway"
        let gateway = storage.insertNewObject(ofType: PaymentGateway.self)
        gateway.siteID = sampleSiteID
        gateway.gatewayID = gatewayID

        // When
        let storedGateway = try XCTUnwrap(storage.loadPaymentGateway(siteID: sampleSiteID, gatewayID: gatewayID))

        // Then
        XCTAssertEqual(gateway, storedGateway)
    }

    func test_loadAllShippingLabels_by_siteID_orderID() throws {
        // Given
        let orderID: Int64 = 123
        let label1 = storage.insertNewObject(ofType: ShippingLabel.self)
        label1.siteID = sampleSiteID
        label1.orderID = orderID

        let label2 = storage.insertNewObject(ofType: ShippingLabel.self)
        label2.siteID = sampleSiteID
        label2.orderID = orderID

        // When
        let storedLabels = try XCTUnwrap(storage.loadAllShippingLabels(siteID: sampleSiteID, orderID: orderID))

        // Then
        XCTAssertEqual(Set([label1, label2]), Set(storedLabels))
    }

    func test_loadShippingLabel_by_siteID_orderID_labelID() throws {
        // Given
        let orderID: Int64 = 123
        let labelID: Int64 = 1233
        let label = storage.insertNewObject(ofType: ShippingLabel.self)
        label.siteID = sampleSiteID
        label.orderID = orderID
        label.shippingLabelID = labelID

        // When
        let storedLabel = try XCTUnwrap(storage.loadShippingLabel(siteID: sampleSiteID, orderID: orderID, shippingLabelID: labelID))

        // Then
        XCTAssertEqual(label, storedLabel)
    }

    func test_loadShippingLabelSettings_by_siteID_orderID() throws {
        // Given
        let orderID: Int64 = 123
        let labelSettings = storage.insertNewObject(ofType: ShippingLabelSettings.self)
        labelSettings.siteID = sampleSiteID
        labelSettings.orderID = orderID

        // When
        let storedLabelSettings = try XCTUnwrap(storage.loadShippingLabelSettings(siteID: sampleSiteID, orderID: orderID))

        // Then
        XCTAssertEqual(labelSettings, storedLabelSettings)
    }
}
