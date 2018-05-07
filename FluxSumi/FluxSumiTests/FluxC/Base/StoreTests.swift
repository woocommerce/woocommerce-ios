import XCTest
@testable import FluxSumi


// MARK: - Store Unit Tests!
//
class StoreTests: XCTestCase {

    let dispatcher = Dispatcher.global
    var accountStore: MockupAccountStore!
    var siteStore: MockupSiteStore!

    override func setUp() {
        accountStore = MockupAccountStore()
        siteStore = MockupSiteStore()
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
