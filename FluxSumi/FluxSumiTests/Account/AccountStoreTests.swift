import XCTest
@testable import FluxSumi
@testable import Networking
@testable import Storage



/// AccountStore Unit Tests
///
class AccountStoreTests: XCTestCase {

    var storageManager: MockupStorageManager!

    override func setUp() {
        super.setUp()
        storageManager = MockupStorageManager()
    }


    /// Verifies that `updateStoredAccount` does not produce duplicate entries.
    ///
    func testUpdateStoredAccountEffectivelyUpdatesPreexistantAccounts() {
        let accountStore = AccountStore(dispatcher: .global, storageManager: storageManager)

        let previousCount = storageManager.viewStorage.countObjects(ofType: Storage.Account.self, matching: nil)
        XCTAssertEqual(previousCount, 0)

        accountStore.updateStoredAccount(remote: sampleAccountPristine())
        accountStore.updateStoredAccount(remote: sampleAccountUpdate())

        let laterCount = storageManager.viewStorage.countObjects(ofType: Storage.Account.self, matching: nil)
        XCTAssertEqual(laterCount, 1)

        let expectedAccount = sampleAccountUpdate()
        let storageAccount = accountStore.loadStoredAccount(userId: expectedAccount.userID)!
        compare(storageAccount: storageAccount, remoteAccount: expectedAccount)
    }

    /// Verifies that `updateStoredAccount` effectively inserts a new Account, with the specified payload.
    ///
    func testUpdateStoredAccountEffectivelyPersistsNewAccounts() {
        let accountStore = AccountStore(dispatcher: .global, storageManager: storageManager)
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
