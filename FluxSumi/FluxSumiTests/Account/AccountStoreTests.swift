import XCTest
@testable import FluxSumi
@testable import Networking
@testable import Storage



/// AccountStore Unit Tests
///
class AccountStoreTests: XCTestCase {

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!


    override func setUp() {
        super.setUp()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }


    /// Verifies that synchronizeDotcomAccount returns an error, whenever there is not backend response.
    ///
    func testSynchronizeDotcomAccountReturnsErrorUponEmptyResponse() {
        let accountStore = AccountStore(storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Synchronize")

        accountStore.synchronizeDotcomAccount(authToken: "Dummy") { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    /// Verifies that synchronizeDotcomAccount effectively inserts a new Default Account.
    ///
    func testSynchronizeDotcomAccountInsertsRetrievedAccountDetailsIntoPermanentStorage() {
        let accountStore = AccountStore(storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Synchronize")

        network.simulateResponse(requestUrlSuffix: "me", filename: "me")
        XCTAssertNil(storageManager.viewStorage.firstObject(ofType: Storage.Account.self, matching: nil))

        accountStore.synchronizeDotcomAccount(authToken: "Dummy") { error in
            guard let account = self.storageManager.viewStorage.firstObject(ofType: Storage.Account.self, matching: nil) else {
                XCTFail()
                return
            }

            XCTAssertNil(error)
            XCTAssertEqual(account.userID, Int64(78972699))
            XCTAssertEqual(account.username, "apiexamples")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    /// Verifies that `updateStoredAccount` does not produce duplicate entries.
    ///
    func testUpdateStoredAccountEffectivelyUpdatesPreexistantAccounts() {
        let accountStore = AccountStore(storageManager: storageManager, network: network)

        XCTAssertNil(storageManager.viewStorage.firstObject(ofType: Storage.Account.self, matching: nil))

        accountStore.updateStoredAccount(remote: sampleAccountPristine())
        accountStore.updateStoredAccount(remote: sampleAccountUpdate())

        XCTAssert(storageManager.viewStorage.countObjects(ofType: Storage.Account.self, matching: nil) == 1)

        let expectedAccount = sampleAccountUpdate()
        let storageAccount = accountStore.loadStoredAccount(userId: expectedAccount.userID)!
        compare(storageAccount: storageAccount, remoteAccount: expectedAccount)
    }

    /// Verifies that `updateStoredAccount` effectively inserts a new Account, with the specified payload.
    ///
    func testUpdateStoredAccountEffectivelyPersistsNewAccounts() {
        let accountStore = AccountStore(storageManager: storageManager, network: network)
        let remoteAccount = sampleAccountPristine()

        XCTAssertNil(accountStore.loadStoredAccount(userId: remoteAccount.userID))
        accountStore.updateStoredAccount(remote: remoteAccount)

        let storageAccount = accountStore.loadStoredAccount(userId: remoteAccount.userID)!
        compare(storageAccount: storageAccount, remoteAccount: remoteAccount)
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
