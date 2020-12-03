import XCTest
@testable import Yosemite
@testable import Networking


// MARK: - Store Unit Tests!
//
class StoreTests: XCTestCase {

    private let dispatcher = Dispatcher()
    private let storageManager = MockStorageManager()
    private let network = MockNetwork()
    private var accountStore: MockupAccountStore!
    private var siteStore: MockupSiteStore!

    override func setUp() {
        accountStore = MockupAccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        siteStore = MockupSiteStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }


    /// Verifies that Account Actions are only received by the Account Store.
    ///
    func testOnlyAccountStoreHandlesAccountActions() {
        XCTAssertTrue(accountStore.receivedActions.isEmpty)
        XCTAssertTrue(siteStore.receivedActions.isEmpty)

        dispatcher.dispatch(MockupAccountAction.authenticate)
        XCTAssertEqual(accountStore.receivedActions.count, 1)
        XCTAssertTrue(siteStore.receivedActions.isEmpty)
    }
}
