import XCTest

@testable import Storage

class StorageTypeExtensionsTests: XCTestCase {

    private let sampleSiteID: Int64 = 1234

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

    /*
    func test_load<#methodName#>_by_<#params#>() throws {
        // Given
        let <#param#> = <#param#>
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
