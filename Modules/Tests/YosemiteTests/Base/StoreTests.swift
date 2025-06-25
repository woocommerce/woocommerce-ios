import XCTest
@testable import Yosemite
@testable import Networking


// MARK: - Store Unit Tests!
//
class StoreTests: XCTestCase {

    private let dispatcher = Dispatcher()
    private let storageManager = MockStorageManager()
    private let network = MockNetwork()
    private var accountStore: MockAccountStore!
    private var siteStore: MockSiteStore!

    override func setUp() {
        accountStore = MockAccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        siteStore = MockSiteStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }


    /// Verifies that Account Actions are only received by the Account Store.
    ///
    func testOnlyAccountStoreHandlesAccountActions() {
        XCTAssertTrue(accountStore.receivedActions.isEmpty)
        XCTAssertTrue(siteStore.receivedActions.isEmpty)

        dispatcher.dispatch(MockAccountAction.authenticate)
        XCTAssertEqual(accountStore.receivedActions.count, 1)
        XCTAssertTrue(siteStore.receivedActions.isEmpty)
    }
}
