import XCTest
@testable import FluxSumi


// MARK: - Store Unit Tests!
//
class StoreTests: XCTestCase {

    let dispatcher = Dispatcher.global
    let storageManager = MockupStorageManager()
    var accountStore: MockupAccountStore!
    var siteStore: MockupSiteStore!

    override func setUp() {
        accountStore = MockupAccountStore(storageManager: storageManager)
        siteStore = MockupSiteStore(storageManager: storageManager)
    }


    /// Verifies that Account Actions are only received by the Account Store.
    ///
    func testOnlyAccountStoreHandlesAccountActions() {
        XCTAssertTrue(accountStore.receivedActions.isEmpty)
        XCTAssertTrue(siteStore.receivedActions.isEmpty)

        dispatcher.dispatch(AccountAction.authenticate)
        XCTAssertEqual(accountStore.receivedActions.count, 1)
        XCTAssertTrue(siteStore.receivedActions.isEmpty)
    }
}
