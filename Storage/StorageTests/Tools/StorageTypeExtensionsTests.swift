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

    /*
    func test_load<#methodName#>_by_<#params#>() throws {
        // Given
        let <#param#>: Int64 = <#param#>
        let <#param#>: Int64 = <#param#>
        let <#entity#> = storage.insertNewObject(ofType: <#type#>.self)
        <#entity#>.<#param#> = <#param#>
        <#entity#>.<#param#> = <#param#>

        // When
        let stored<#entity#> = try XCTUnwrap(storage.<#loadMethod#>)

        // Then
        XCTAssertEqual(<#entity#>, stored<#entity#>)
    }
     */
}
