import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage



/// AccountStore Unit Tests
///
class AccountStoreTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }


    /// Verifies that AccountAction.synchronizeAccount returns an error, whenever there is not backend response.
    ///
    func testSynchronizeAccountReturnsErrorUponEmptyResponse() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Synchronize")

        let action = AccountAction.synchronizeAccount { (account, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(account)
            expectation.fulfill()
        }

        accountStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    /// Verifies that AccountAction.synchronizeAccount returns an error whenever there is an error response from the backend.
    ///
    func testSynchronizeAccountReturnsErrorUponReponseError() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Synchronize")

        network.simulateResponse(requestUrlSuffix: "me", filename: "generic_error")
        let action = AccountAction.synchronizeAccount { (account, error) in
            XCTAssertNil(account)
            XCTAssertNotNil(error)
            guard let _ = error as NSError? else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }

        accountStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    /// Verifies that AccountAction.synchronizeAccount effectively inserts a new Default Account.
    ///
    func testSynchronizeAccountreturnsExpectedAccountDetails() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Synchronize")

        network.simulateResponse(requestUrlSuffix: "me", filename: "me")
        XCTAssertNil(storageManager.viewStorage.firstObject(ofType: Storage.Account.self, matching: nil))

        let action = AccountAction.synchronizeAccount { (account, error) in
            XCTAssertNil(error)
            XCTAssertEqual(account?.userID, 78972699)
            XCTAssertEqual(account?.username, "apiexamples")

            expectation.fulfill()
        }

        accountStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    /// Verifies that `updateStoredAccount` does not produce duplicate entries.
    ///
    func testUpdateStoredAccountEffectivelyUpdatesPreexistantAccounts() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertNil(storageManager.viewStorage.firstObject(ofType: Storage.Account.self, matching: nil))

        accountStore.upsertStoredAccount(remote: sampleAccountPristine())
        accountStore.upsertStoredAccount(remote: sampleAccountUpdate())

        XCTAssert(storageManager.viewStorage.countObjects(ofType: Storage.Account.self, matching: nil) == 1)

        let expectedAccount = sampleAccountUpdate()
        let storageAccount = accountStore.loadStoredAccount(userId: expectedAccount.userID)!
        compare(storageAccount: storageAccount, remoteAccount: expectedAccount)
    }

    /// Verifies that `updateStoredAccount` effectively inserts a new Account, with the specified payload.
    ///
    func testUpdateStoredAccountEffectivelyPersistsNewAccounts() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteAccount = sampleAccountPristine()

        XCTAssertNil(accountStore.loadStoredAccount(userId: remoteAccount.userID))
        accountStore.upsertStoredAccount(remote: remoteAccount)

        let storageAccount = accountStore.loadStoredAccount(userId: remoteAccount.userID)!
        compare(storageAccount: storageAccount, remoteAccount: remoteAccount)
    }

    /// Verifies that AccountAction.retrieveAccount returns the expected Account.
    ///
    func testRetrieveAccountReturnsEntityWithExpectedFields() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let sampleAccount = sampleAccountPristine()

        let expectation = self.expectation(description: "Synchronize")
        accountStore.upsertStoredAccount(remote: sampleAccount)

        let retrieveAccountAction = AccountAction.retrieveAccount(userId: sampleAccount.userID) { account in
            guard let retrieved = account else {
                XCTFail()
                return
            }

            XCTAssertEqual(retrieved.displayName, sampleAccount.displayName)
            XCTAssertEqual(retrieved.email, sampleAccount.email)
            XCTAssertEqual(retrieved.gravatarUrl, sampleAccount.gravatarUrl)
            XCTAssertEqual(retrieved.userID, sampleAccount.userID)
            XCTAssertEqual(retrieved.username, sampleAccount.username)
            expectation.fulfill()
        }

        accountStore.onAction(retrieveAccountAction)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}


// MARK: - Private Methods
//
private extension AccountStoreTests {

    /// Verifies that the Storage.Account fields match with the specified Networking.Account.
    ///
    func compare(storageAccount: Storage.Account, remoteAccount: Networking.Account) {
        XCTAssertEqual(storageAccount.userID, Int64(remoteAccount.userID))
        XCTAssertEqual(storageAccount.displayName, remoteAccount.displayName)
        XCTAssertEqual(storageAccount.email, remoteAccount.email)
        XCTAssertEqual(storageAccount.username, remoteAccount.username)
        XCTAssertEqual(storageAccount.gravatarUrl, remoteAccount.gravatarUrl)
    }

    /// Sample Account: Mark I
    ///
    func sampleAccountPristine() -> Networking.Account {
        return Account(userID: 1234,
                       displayName: "Sample",
                       email: "email@email.com",
                       username: "Username!",
                       gravatarUrl: "https://automattic.com/superawesomegravatar.png")
    }

    /// Sample Account: Mark II
    ///
    func sampleAccountUpdate() -> Networking.Account {
        return Account(userID: 1234,
                       displayName: "Yosemite",
                       email: "yosemite@yosemite.com",
                       username: "YOLO",
                       gravatarUrl: "https://automattic.com/yosemite.png")
    }
}
