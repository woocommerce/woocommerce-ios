import XCTest

@testable import Storage

class StorageTypeExtensionsTests: XCTestCase {

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
}
