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

    private let jcpSitePredicate = \StorageSite.isJetpackThePluginInstalled == false && \StorageSite.isJetpackConnected == true
    private let jetpackSitePredicate = \StorageSite.isJetpackThePluginInstalled == true && \StorageSite.isJetpackConnected == true

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
            let action = AccountAction.synchronizeSites(selectedSiteID: nil, isJetpackConnectionPackageSupported: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `synchronizeSites` effectively persists any retrieved sites when all sites have Jetpack-the-plugin.
    ///
    func test_synchronizeSites_effectively_persists_retrieved_sites() {
        // Given
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: 1, isJetpackThePluginInstalled: true, isJetpackConnected: true),
            Site.fake().copy(siteID: 2, isJetpackThePluginInstalled: true, isJetpackConnected: true)
        ])
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites(selectedSiteID: nil, isJetpackConnectionPackageSupported: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadSites])

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self, matching: jetpackSitePredicate), 2)
    }

    /// Verifies that `synchronizeSites` effectively persists a Jetpack Connection Package site and a Jetpack site.
    ///
    func test_synchronizeSites_effectively_persists_jetpack_cp_and_jetpack_sites() throws {
        // Given
        let siteIDOfJCPSite = Int64(255)
        let siteIDOfJetpackSite = Int64(166)
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: siteIDOfJCPSite,
                             name: "old name",
                             description: "old description",
                             url: "oldurl",
                             isJetpackThePluginInstalled: false,
                             isJetpackConnected: true),
            Site.fake().copy(siteID: siteIDOfJetpackSite, isJetpackThePluginInstalled: true, isJetpackConnected: true)
        ])
        remote.whenFetchingWordPressSiteSettings(siteID: siteIDOfJCPSite, thenReturn: .success(.init(name: "new name",
                                                                                                     description: "new description",
                                                                                                     url: "newurl")))
        remote.whenCheckingIfWooCommerceIsActive(siteID: siteIDOfJCPSite, thenReturn: .success(true))

        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites(selectedSiteID: nil, isJetpackConnectionPackageSupported: true) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations,
                       [.loadSites, .checkIfWooCommerceIsActive(siteID: siteIDOfJCPSite), .fetchWordPressSiteSettings(siteID: siteIDOfJCPSite)])

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 2)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self, matching: jcpSitePredicate), 1)
        let jcpSite = try XCTUnwrap(viewStorage.firstObject(ofType: Storage.Site.self, matching: jcpSitePredicate))
        XCTAssertEqual(jcpSite.siteID, siteIDOfJCPSite)
        XCTAssertEqual(jcpSite.name, "new name")
        XCTAssertEqual(jcpSite.tagline, "new description")
        XCTAssertEqual(jcpSite.url, "newurl")
        XCTAssertTrue(jcpSite.isWooCommerceActive?.boolValue == true)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self, matching: jetpackSitePredicate), 1)
        let jetpackSite = try XCTUnwrap(viewStorage.firstObject(ofType: Storage.Site.self, matching: jetpackSitePredicate))
        XCTAssertEqual(jetpackSite.siteID, siteIDOfJetpackSite)
    }

    /// Verifies that `synchronizeSites` effectively persists all sites when the response contains a JCP site while the feature flag is off.
    /// The JCP site is still persisted but the information is not accurate.
    ///
    func test_synchronizeSites_effectively_persists_sites_with_jcp_feature_off() throws {
        // Given
        let siteIDOfJCPSite = Int64(255)
        let siteIDOfJetpackSite = Int64(166)
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: siteIDOfJCPSite,
                             name: "old name",
                             description: "old description",
                             url: "oldurl",
                             isJetpackThePluginInstalled: false,
                             isJetpackConnected: true),
            Site.fake().copy(siteID: siteIDOfJetpackSite, isJetpackThePluginInstalled: true, isJetpackConnected: true)
        ])

        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites(selectedSiteID: nil, isJetpackConnectionPackageSupported: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadSites])

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 2)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self, matching: jcpSitePredicate), 1)
        let jcpSite = try XCTUnwrap(viewStorage.firstObject(ofType: Storage.Site.self, matching: jcpSitePredicate))
        XCTAssertEqual(jcpSite.siteID, siteIDOfJCPSite)
        XCTAssertEqual(jcpSite.name, "old name")
        XCTAssertEqual(jcpSite.tagline, "old description")
        XCTAssertEqual(jcpSite.url, "oldurl")

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self, matching: jetpackSitePredicate), 1)
        let jetpackSite = try XCTUnwrap(viewStorage.firstObject(ofType: Storage.Site.self, matching: jetpackSitePredicate))
        XCTAssertEqual(jetpackSite.siteID, siteIDOfJetpackSite)
    }

    /// Verifies that `synchronizeSites` effectively persists a Jetpack Connection Package site with original metadata when WP site settings request fails.
    ///
    func test_synchronizeSites_persists_a_jetpack_cp_site_with_existing_metadata_when_wp_settings_request_fails() throws {
        // Given
        let siteID = Int64(255)
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: siteID,
                             name: "old name",
                             description: "old description",
                             url: "oldurl",
                             isJetpackThePluginInstalled: false,
                             isJetpackConnected: true)
        ])
        remote.whenFetchingWordPressSiteSettings(siteID: siteID, thenReturn: .failure(NetworkError.timeout))
        remote.whenCheckingIfWooCommerceIsActive(siteID: siteID, thenReturn: .success(true))

        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites(selectedSiteID: nil, isJetpackConnectionPackageSupported: true) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadSites, .checkIfWooCommerceIsActive(siteID: siteID), .fetchWordPressSiteSettings(siteID: siteID)])

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 1)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self, matching: jcpSitePredicate), 1)
        let jcpSite = try XCTUnwrap(viewStorage.firstObject(ofType: Storage.Site.self, matching: jcpSitePredicate))
        XCTAssertEqual(jcpSite.siteID, siteID)
        XCTAssertEqual(jcpSite.name, "old name")
        XCTAssertEqual(jcpSite.tagline, "old description")
        XCTAssertEqual(jcpSite.url, "oldurl")
        XCTAssertTrue(jcpSite.isWooCommerceActive?.boolValue == true)
    }

    /// Verifies that `synchronizeSites` persists a Jetpack Connection Package site with original isWooCommerceActive when WC site settings request fails.
    ///
    func test_synchronizeSites_persists_a_jetpack_cp_site_without_isWooCommerceActive_change_when_wc_settings_request_fails() throws {
        // Given
        let siteID = Int64(255)
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: siteID, isJetpackThePluginInstalled: false, isJetpackConnected: true, isWooCommerceActive: false)
        ])
        remote.whenFetchingWordPressSiteSettings(siteID: siteID, thenReturn: .success(.init(name: "new name",
                                                                                                     description: "new description",
                                                                                                     url: "newurl")))
        remote.whenCheckingIfWooCommerceIsActive(siteID: siteID, thenReturn: .failure(NetworkError.timeout))

        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites(selectedSiteID: nil, isJetpackConnectionPackageSupported: true) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadSites, .checkIfWooCommerceIsActive(siteID: siteID), .fetchWordPressSiteSettings(siteID: siteID)])

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self, matching: jcpSitePredicate), 1)
        let jcpSite = try XCTUnwrap(viewStorage.firstObject(ofType: Storage.Site.self, matching: jcpSitePredicate))
        XCTAssertEqual(jcpSite.siteID, siteID)
        XCTAssertTrue(jcpSite.isWooCommerceActive?.boolValue == false)
        XCTAssertFalse(jcpSite.isJetpackThePluginInstalled)
        XCTAssertTrue(jcpSite.isJetpackConnected)
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
            let action = AccountAction.synchronizeSites(selectedSiteID: nil, isJetpackConnectionPackageSupported: false) { result in
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
            let action = AccountAction.synchronizeSites(selectedSiteID: selectedSiteID, isJetpackConnectionPackageSupported: false) { result in
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

    // MARK: - AccountAction.loadAndSynchronizeSite

    func test_loadAndSynchronizeSite_returns_site_already_in_storage_without_making_network_request_if_forcedUpdate_is_false() throws {
        // Given
        let network = MockNetwork()
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        let siteID = Int64(999)
        let sampleSite = sampleSitePristine().copy(siteID: siteID)
        let group = DispatchGroup()
        group.enter()
        accountStore.upsertStoredSitesInBackground(readOnlySites: [sampleSite]) {
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 1)
            group.leave()
        }

        // When
        let result: Result<Yosemite.Site, Error> = waitFor { promise in
            group.notify(queue: .main) {
                let action = AccountAction.loadAndSynchronizeSite(siteID: siteID, forcedUpdate: false, isJetpackConnectionPackageSupported: false) { result in
                    XCTAssertTrue(Thread.isMainThread)
                    promise(result)
                }
                accountStore.onAction(action)
            }
        }

        // Then
        let site = try XCTUnwrap(result.get())
        XCTAssertEqual(site, sampleSite)
        XCTAssertEqual(network.requestsForResponseData.count, 0)
    }

    func test_loadAndSynchronizeSite_fetches_from_remote_if_forcedUpdate_is_true() throws {
        // Given
        let network = MockNetwork()
        network.simulateResponse(requestUrlSuffix: "me/sites", filename: "sites")
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        // The site ID value is in `sites.json` used in the mock network.
        let siteIDInSimulatedResponse = Int64(1112233334444555)
        let sampleSite = sampleSitePristine().copy(siteID: siteIDInSimulatedResponse, isWooCommerceActive: false)
        let group = DispatchGroup()
        group.enter()
        accountStore.upsertStoredSitesInBackground(readOnlySites: [sampleSite]) {
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 1)
            group.leave()
        }

        // When
        let result: Result<Yosemite.Site, Error> = waitFor { promise in
            group.notify(queue: .main) {
                let action = AccountAction.loadAndSynchronizeSite(siteID: siteIDInSimulatedResponse,
                                                                  forcedUpdate: true,
                                                                  isJetpackConnectionPackageSupported: false) { result in
                    XCTAssertTrue(Thread.isMainThread)
                    promise(result)
                }
                accountStore.onAction(action)
            }
        }

        // Then
        let site = try XCTUnwrap(result.get())
        XCTAssertEqual(site.isWooCommerceActive, true) // the value in `sites.json` - not the one in storage.
        XCTAssertEqual(network.requestsForResponseData.count, 1)
    }

    func test_loadAndSynchronizeSite_returns_unknown_site_error_after_syncing_failure() throws {
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
                let action = AccountAction.loadAndSynchronizeSite(siteID: 9999, forcedUpdate: false, isJetpackConnectionPackageSupported: false) { result in
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

    func test_loadAndSynchronizeSite_returns_site_after_syncing_success() throws {
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
                let action = AccountAction.loadAndSynchronizeSite(siteID: siteIDInSimulatedResponse,
                                                                  forcedUpdate: true,
                                                                  isJetpackConnectionPackageSupported: false) { result in
                    XCTAssertTrue(Thread.isMainThread)
                    promise(result)
                }
                accountStore.onAction(action)
            }
        }

        // Then
        let site = try XCTUnwrap(result.get())
        XCTAssertEqual(site.siteID, siteIDInSimulatedResponse)
    }

    func test_loadAndSynchronizeSite_makes_3_network_requests_when_one_site_is_jetpack_cp_connected() throws {
        // Given
        let network = MockNetwork()
        let remote = MockAccountRemote()
        let siteIDOfJCPSite = Int64(255)
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: 1, isJetpackThePluginInstalled: true, isJetpackConnected: true),
            Site.fake().copy(siteID: siteIDOfJCPSite, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        ])
        remote.whenCheckingIfWooCommerceIsActive(siteID: siteIDOfJCPSite, thenReturn: .success(true))
        remote.whenFetchingWordPressSiteSettings(siteID: siteIDOfJCPSite, thenReturn: .failure(NetworkError.notFound))
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let _: Void = waitFor { promise in
            let action = AccountAction.loadAndSynchronizeSite(siteID: 123, forcedUpdate: true, isJetpackConnectionPackageSupported: true) { result in
                promise(())
            }
            accountStore.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations,
                       [.loadSites, .checkIfWooCommerceIsActive(siteID: siteIDOfJCPSite), .fetchWordPressSiteSettings(siteID: siteIDOfJCPSite)])
    }

    func test_loadAndSynchronizeSite_makes_1_network_request_when_one_site_is_jetpack_cp_connected_with_jcp_feature_off() throws {
        // Given
        let network = MockNetwork()
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: 1, isJetpackThePluginInstalled: true, isJetpackConnected: true),
            Site.fake().copy(siteID: 2, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        ])
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let _: Void = waitFor { promise in
            let action = AccountAction.loadAndSynchronizeSite(siteID: 123, forcedUpdate: true, isJetpackConnectionPackageSupported: false) { result in
                promise(())
            }
            accountStore.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadSites])
    }

    func test_loadAndSynchronizeSite_makes_1_network_requests_when_all_sites_have_jetpack_plugin() throws {
        // Given
        let network = MockNetwork()
        let remote = MockAccountRemote()
        let siteIDOfJCPSite = Int64(255)
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: 1, isJetpackThePluginInstalled: true, isJetpackConnected: true),
            Site.fake().copy(siteID: siteIDOfJCPSite, isJetpackThePluginInstalled: true, isJetpackConnected: true)
        ])
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let _: Void = waitFor { promise in
            let action = AccountAction.loadAndSynchronizeSite(siteID: 123, forcedUpdate: true, isJetpackConnectionPackageSupported: true) { result in
                promise(())
            }
            accountStore.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadSites])
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
