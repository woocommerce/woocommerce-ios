import Fakes
import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage



/// AccountStore Unit Tests
///
final class AccountStoreTests: XCTestCase {

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
    func test_synchronizeAccount_returns_error_upon_empty_response() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Yosemite.Account, Error> = waitFor { promise in
            let action = AccountAction.synchronizeAccount { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }


    /// Verifies that AccountAction.synchronizeAccount returns an error whenever there is an error response from the backend.
    ///
    func test_synchronizeAccount_returns_error_upon_reponse_error() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "me", filename: "generic_error")

        // When
        let result: Result<Yosemite.Account, Error> = waitFor { promise in
            let action = AccountAction.synchronizeAccount { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }


    /// Verifies that AccountAction.synchronizeAccount effectively inserts a new Default Account.
    ///
    func test_synchronizeAccount_returns_expected_account_details() throws {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "me", filename: "me")
        XCTAssertNil(viewStorage.firstObject(ofType: Storage.Account.self, matching: nil))

        // When
        let result: Result<Yosemite.Account, Error> = waitFor { promise in
            let action = AccountAction.synchronizeAccount { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        XCTAssertEqual(account.userID, 78972699)
        XCTAssertEqual(account.username, "apiexamples")
        XCTAssertNotNil(viewStorage.firstObject(ofType: Storage.Account.self, matching: nil))
    }

    // MARK: - AccountStore + Account + Storage

    /// Verifies that `updateStoredAccount` does not produce duplicate entries.
    ///
    func test_upsertStoredAccount_effectively_updates_preexistant_accounts() {
        // Given
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        XCTAssertNil(viewStorage.firstObject(ofType: Storage.Account.self, matching: nil))

        // When
        accountStore.upsertStoredAccount(readOnlyAccount: sampleAccountPristine())
        accountStore.upsertStoredAccount(readOnlyAccount: sampleAccountUpdate())

        // Then
        XCTAssert(viewStorage.countObjects(ofType: Storage.Account.self, matching: nil) == 1)

        let expectedAccount = sampleAccountUpdate()
        let storageAccount = viewStorage.loadAccount(userID: expectedAccount.userID)!
        compare(storageAccount: storageAccount, remoteAccount: expectedAccount)
    }

    /// Verifies that `updateStoredAccount` effectively inserts a new Account, with the specified payload.
    ///
    func test_upsertStoredAccount_effectively_persists_new_accounts() {
        // Given
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteAccount = sampleAccountPristine()
        XCTAssertNil(viewStorage.loadAccount(userID: remoteAccount.userID))

        // When
        accountStore.upsertStoredAccount(readOnlyAccount: remoteAccount)

        // Then
        let storageAccount = viewStorage.loadAccount(userID: remoteAccount.userID)!
        compare(storageAccount: storageAccount, remoteAccount: remoteAccount)
    }

    // MARK: - AccountAction.synchronizeAccountSettings

    /// Verifies that `synchronizeAccountSettings` returns an error, whenever there is no backend reply.
    ///
    func test_synchronizeAccountSettings_returns_error_on_empty_response() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Yosemite.AccountSettings, Error> = waitFor { promise in
            let action = AccountAction.synchronizeAccountSettings(userID: 10) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `synchronizeAccountSettings` effectively persists any retrieved settings.
    ///
    func test_synchronizeAccountSettings_effectively_persists_retrieved_settings() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "me/settings", filename: "me-settings")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.AccountSettings.self), 0)

        // When
        let result: Result<Yosemite.AccountSettings, Error> = waitFor { promise in
            let action = AccountAction.synchronizeAccountSettings(userID: 10) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.AccountSettings.self), 1)
    }

    /// Verifies that `synchronizeAccountSettings` effectively update any retrieved settings.
    ///
    func test_synchronizeAccountSettings_effectively_update_retrieved_settings() throws {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        storageManager.insertSampleAccountSettings(readOnlyAccountSettings: sampleAccountSettings())
        network.simulateResponse(requestUrlSuffix: "me/settings", filename: "me-settings")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.AccountSettings.self), 1)

        // When
        let result: Result<Yosemite.AccountSettings, Error> = waitFor { promise in
            let action = AccountAction.synchronizeAccountSettings(userID: 10) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let account = try result.get()
        let expectedAccount = Networking.AccountSettings(userID: 10,
                                                         tracksOptOut: true,
                                                         firstName: "Dem 123",
                                                         lastName: "Nines")
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.AccountSettings.self), 1)
        XCTAssertEqual(account, expectedAccount)
    }

    // MARK: - AccountAction.synchronizeSites

    /// Verifies that `synchronizeSites` returns an error, whenever there is no backend reply.
    ///
    func test_synchronizeSites_returns_error_on_empty_response() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites(selectedSiteID: nil) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `synchronizeSites` effectively persists any retrieved sites.
    ///
    func test_synchronizeSites_effectively_persists_retrieved_sites() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "me/sites", filename: "sites")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites(selectedSiteID: nil) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 2)
    }

    /// Verifies that `synchronizeSites` deletes storage sites that do not exist remotely anymore.
    ///
    func test_synchronizeSites_deletes_sites_that_do_not_exist_remotely() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let siteIDInStorageOnly = Int64(127)
        storageManager.insertSampleSite(readOnlySite: Site.fake().copy(siteID: siteIDInStorageOnly))
        network.simulateResponse(requestUrlSuffix: "me/sites", filename: "sites")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 1)
        XCTAssertNotNil(viewStorage.loadSite(siteID: siteIDInStorageOnly))

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites(selectedSiteID: nil) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        // `sites.json` contains 2 sites that do not match `siteIDInStorageOnly`.
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 2)
        XCTAssertNil(viewStorage.loadSite(siteID: siteIDInStorageOnly))
    }

    /// Verifies that `synchronizeSites` does not delete selected site after syncing and the selected site does not exist remotely anymore.
    ///
    func test_synchronizeSites_does_not_delete_selected_site_that_does_not_exist_remotely() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let selectedSiteID = Int64(127)
        storageManager.insertSampleSite(readOnlySite: Site.fake().copy(siteID: selectedSiteID))
        network.simulateResponse(requestUrlSuffix: "me/sites", filename: "sites")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 1)
        XCTAssertNotNil(viewStorage.loadSite(siteID: selectedSiteID))

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites(selectedSiteID: selectedSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        // `sites.json` contains 2 sites that do not match `siteIDInStorageOnly`.
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 3)
        XCTAssertNotNil(viewStorage.loadSite(siteID: selectedSiteID))
    }

    // MARK: - AccountAction.loadAccount

    func test_loadAccount_returns_expected_account() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Account.self), 0)
        store.upsertStoredAccount(readOnlyAccount: sampleAccountPristine())
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Account.self), 1)

        // When
        let account: Yosemite.Account? = waitFor { promise in
            let action = AccountAction.loadAccount(userID: 1234) { account in
                promise(account)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertNotNil(account)
        XCTAssertEqual(account, sampleAccountPristine())
    }

    func test_loadAccount_returns_nil_for_unknown_account() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Account.self), 0)
        store.upsertStoredAccount(readOnlyAccount: sampleAccountPristine())
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Account.self), 1)

        // When
        let account: Yosemite.Account? = waitFor { promise in
            let action = AccountAction.loadAccount(userID: 9999) { account in
                promise(account)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertNil(account)
    }

    // MARK: - AccountAction.loadAndSynchronizeSiteIfNeeded

    func test_loadAndSynchronizeSiteIfNeeded_returns_site_already_in_storage_without_making_network_request() throws {
        // Given
        let network = MockNetwork()
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        let group = DispatchGroup()
        group.enter()
        accountStore.upsertStoredSitesInBackground(readOnlySites: [sampleSitePristine()]) {
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 1)
            group.leave()
        }

        // When
        let result: Result<Yosemite.Site, Error> = waitFor { promise in
            group.notify(queue: .main) {
                let action = AccountAction.loadAndSynchronizeSiteIfNeeded(siteID: 999) { result in
                    XCTAssertTrue(Thread.isMainThread)
                    promise(result)
                }
                accountStore.onAction(action)
            }
        }

        // Then
        let site = try XCTUnwrap(result.get())
        XCTAssertEqual(site, sampleSitePristine())
        XCTAssertEqual(network.requestsForResponseData.count, 0)
    }

    func test_loadAndSynchronizeSiteIfNeeded_returns_unknown_site_error_after_syncing_failure() throws {
        // Given
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let group = DispatchGroup()
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        group.enter()
        accountStore.upsertStoredSitesInBackground(readOnlySites: [sampleSitePristine()]) {
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 1)
            group.leave()
        }

        // When
        let result: Result<Yosemite.Site, Error> = waitFor { promise in
            group.notify(queue: .main) {
                let action = AccountAction.loadAndSynchronizeSiteIfNeeded(siteID: 9999) { result in
                    XCTAssertTrue(Thread.isMainThread)
                    promise(result)
                }
                accountStore.onAction(action)
            }
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? SynchronizeSiteError, .unknownSite)
        XCTAssertEqual(network.requestsForResponseData.count, 1)
        XCTAssertTrue(((network.requestsForResponseData.first?.urlRequest?.url?.absoluteString.contains("me/sites")) == true))
    }

    func test_loadAndSynchronizeSiteIfNeeded_returns_site_after_syncing_success() throws {
        // Given
        let network = MockNetwork()
        network.simulateResponse(requestUrlSuffix: "me/sites", filename: "sites")
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let group = DispatchGroup()
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        group.enter()
        accountStore.upsertStoredSitesInBackground(readOnlySites: [sampleSitePristine()]) {
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 1)
            group.leave()
        }

        // When
        // The site ID value is in `sites.json` used in the mock network.
        let siteIDInSimulatedResponse = Int64(1112233334444555)
        let result: Result<Yosemite.Site, Error> = waitFor { promise in
            group.notify(queue: .main) {
                let action = AccountAction.loadAndSynchronizeSiteIfNeeded(siteID: siteIDInSimulatedResponse) { result in
                    XCTAssertTrue(Thread.isMainThread)
                    promise(result)
                }
                accountStore.onAction(action)
            }
        }

        // Then
        let site = try XCTUnwrap(result.get())
        XCTAssertEqual(site.siteID, siteIDInSimulatedResponse)
        XCTAssertEqual(network.requestsForResponseData.count, 1)
        XCTAssertTrue(((network.requestsForResponseData.first?.urlRequest?.url?.absoluteString.contains("me/sites")) == true))
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

    func sampleAccountSettings() -> Networking.AccountSettings {
        return AccountSettings(userID: 10,
                               tracksOptOut: true,
                               firstName: nil,
                               lastName: nil)
    }

    /// Sample Site
    ///
    func sampleSitePristine() -> Networking.Site {
        return Site.fake()
    }
}
