import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage



/// AccountStore Unit Tests
///
class AccountStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: - AccountAction.synchronizeAccount

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
    func testSynchronizeAccountReturnsExpectedAccountDetails() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Synchronize")

        network.simulateResponse(requestUrlSuffix: "me", filename: "me")
        XCTAssertNil(viewStorage.firstObject(ofType: Storage.Account.self, matching: nil))

        let action = AccountAction.synchronizeAccount { (account, error) in
            XCTAssertNil(error)
            XCTAssertEqual(account?.userID, 78972699)
            XCTAssertEqual(account?.username, "apiexamples")

            expectation.fulfill()
        }

        accountStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - AccountStore + Account + Storage

    /// Verifies that `updateStoredAccount` does not produce duplicate entries.
    ///
    func testUpdateStoredAccountEffectivelyUpdatesPreexistantAccounts() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertNil(viewStorage.firstObject(ofType: Storage.Account.self, matching: nil))

        accountStore.upsertStoredAccount(readOnlyAccount: sampleAccountPristine())
        accountStore.upsertStoredAccount(readOnlyAccount: sampleAccountUpdate())

        XCTAssert(viewStorage.countObjects(ofType: Storage.Account.self, matching: nil) == 1)

        let expectedAccount = sampleAccountUpdate()
        let storageAccount = viewStorage.loadAccount(userID: expectedAccount.userID)!
        compare(storageAccount: storageAccount, remoteAccount: expectedAccount)
    }

    /// Verifies that `updateStoredAccount` effectively inserts a new Account, with the specified payload.
    ///
    func testUpdateStoredAccountEffectivelyPersistsNewAccounts() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteAccount = sampleAccountPristine()

        XCTAssertNil(viewStorage.loadAccount(userID: remoteAccount.userID))
        accountStore.upsertStoredAccount(readOnlyAccount: remoteAccount)

        let storageAccount = viewStorage.loadAccount(userID: remoteAccount.userID)!
        compare(storageAccount: storageAccount, remoteAccount: remoteAccount)
    }

    // MARK: - AccountAction.synchronizeAccountSettings

    /// Verifies that `synchronizeAccountSettings` returns an error, whenever there is no backend reply.
    ///
    func testSynchronizeAccountSettingsReturnsErrorOnEmptyResponse() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Synchronize")

        let action = AccountAction.synchronizeAccountSettings(userID: 10) { _, error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        accountStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `synchronizeAccountSettings` effectively persists any retrieved settings.
    ///
    func testSynchronizeAccountSettingsEffectivelyPersistsRetrievedSettings() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Synchronize")

        network.simulateResponse(requestUrlSuffix: "me/settings", filename: "me-settings")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.AccountSettings.self), 0)

        let action = AccountAction.synchronizeAccountSettings(userID: 10) { _, error in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.AccountSettings.self), 1)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        accountStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - AccountAction.synchronizeSites

    /// Verifies that `synchronizeSites` returns an error, whenever there is no backend reply.
    ///
    func testSynchronizeSitesReturnsErrorOnEmptyResponse() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Synchronize")

        let action = AccountAction.synchronizeSites { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        accountStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `synchronizeSites` effectively persists any retrieved sites.
    ///
    func testSynchronizeSitesEffectivelyPersistsRetrievedSites() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Synchronize")

        network.simulateResponse(requestUrlSuffix: "me/sites", filename: "sites")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        let action = AccountAction.synchronizeSites { error in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 2)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        accountStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - AccountAction.loadAccount

    func testLoadAccountActionReturnsExpectedAccount() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Load Account Action Success")

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Account.self), 0)
        accountStore.upsertStoredAccount(readOnlyAccount: sampleAccountPristine())
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Account.self), 1)

        let action = AccountAction.loadAccount(userID: 1234) { account in
            XCTAssertNotNil(account)
            XCTAssertEqual(account!, self.sampleAccountPristine())
            expectation.fulfill()
        }

        accountStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func testLoadAccountActionReturnsNilForUnknownAccount() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectation = self.expectation(description: "Load Account Action Error")

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Account.self), 0)
        accountStore.upsertStoredAccount(readOnlyAccount: sampleAccountPristine())
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Account.self), 1)

        let action = AccountAction.loadAccount(userID: 9999) { account in
            XCTAssertNil(account)
            expectation.fulfill()
        }

        accountStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - AccountAction.loadSite

    func testLoadSiteActionReturnsExpectedSite() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let group = DispatchGroup()
        let expectation = self.expectation(description: "Load Site Action Success")

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 0)

        group.enter()
        accountStore.upsertStoredSitesInBackground(readOnlySites: [sampleSitePristine()]) {
            group.leave()
        }

        group.notify(queue: .main) {
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 1)
            let action = AccountAction.loadSite(siteID: 999) { site in
                XCTAssertNotNil(site)
                XCTAssertEqual(site!, self.sampleSitePristine())
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
            accountStore.onAction(action)
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func testLoadSiteActionReturnsNilForUnknownSite() {
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let group = DispatchGroup()
        let expectation = self.expectation(description: "Load Site Action Error")

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 0)

        group.enter()
        accountStore.upsertStoredSitesInBackground(readOnlySites: [sampleSitePristine()]) {
            group.leave()
        }

        group.notify(queue: .main) {
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 1)
            let action = AccountAction.loadSite(siteID: 9999) { site in
                XCTAssertNil(site)
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
            accountStore.onAction(action)
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}


// MARK: - Private Methods
//
private extension AccountStoreTests {

    /// Verifies that the Storage.Account fields match with the specified Networking.Account.
    ///
    func compare(storageAccount: Storage.Account, remoteAccount: Networking.Account) {
        XCTAssertEqual(storageAccount.userID, remoteAccount.userID)
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

    /// Sample Site
    ///
    func sampleSitePristine() -> Networking.Site {
        return Site(siteID: 999,
                    name: "Awesome Test Site",
                    description: "Best description ever!",
                    url: "automattic.com",
                    plan: String(),
                    isWooCommerceActive: true,
                    isWordPressStore: false,
                    timezone: "Asia/Taipei",
                    gmtOffset: 0)
    }
}
