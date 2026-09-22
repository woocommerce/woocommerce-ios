import Combine
import Fakes
import XCTest
import WooFoundation
import YosemiteTestHelpers
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

    @MainActor
    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: - AccountAction.synchronizeAccount

    /// Verifies that AccountAction.synchronizeAccount returns an error, whenever there is not backend response.
    ///
    @MainActor
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
    @MainActor
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
    @MainActor
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
    @MainActor
    func test_upsertStoredAccount_effectively_updates_preexistant_accounts() {
        // Given
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        XCTAssertNil(viewStorage.firstObject(ofType: Storage.Account.self, matching: nil))

        // When
        accountStore.upsertStoredAccount(readOnlyAccount: sampleAccountPristine(), onCompletion: {})
        accountStore.upsertStoredAccount(readOnlyAccount: sampleAccountUpdate(), onCompletion: {})

        // Then
        XCTAssert(viewStorage.countObjects(ofType: Storage.Account.self, matching: nil) == 1)

        let expectedAccount = sampleAccountUpdate()
        let storageAccount = viewStorage.loadAccount(userID: expectedAccount.userID)!
        compare(storageAccount: storageAccount, remoteAccount: expectedAccount)
    }

    /// Verifies that `updateStoredAccount` effectively inserts a new Account, with the specified payload.
    ///
    @MainActor
    func test_upsertStoredAccount_effectively_persists_new_accounts() {
        // Given
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteAccount = sampleAccountPristine()
        XCTAssertNil(viewStorage.loadAccount(userID: remoteAccount.userID))

        // When
        accountStore.upsertStoredAccount(readOnlyAccount: remoteAccount, onCompletion: {})

        // Then
        let storageAccount = viewStorage.loadAccount(userID: remoteAccount.userID)!
        compare(storageAccount: storageAccount, remoteAccount: remoteAccount)
    }

    // MARK: - AccountAction.synchronizeAccountSettings

    /// Verifies that `synchronizeAccountSettings` returns an error, whenever there is no backend reply.
    ///
    @MainActor
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
    @MainActor
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
    @MainActor
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
                                                         crashReportingOptOut: false,
                                                         firstName: "Dem 123",
                                                         lastName: "Nines")
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.AccountSettings.self), 1)
        XCTAssertEqual(account, expectedAccount)
        XCTAssertEqual(viewStorage.loadAccountSettings(userID: 10)?.crashReportingOptOut?.boolValue, false)
    }

    // MARK: - AccountAction.updateCrashReportingOptOut

    /// Verifies that `updateCrashReportingOptOut` submits the setting to the remote and relays a success.
    ///
    @MainActor
    func test_updateCrashReportingOptOut_when_remote_succeeds_then_returns_success() {
        // Given
        let remote = MockAccountRemote()
        remote.whenUpdatingCrashReportingOptOut(thenReturn: .success(()))
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AccountAction.updateCrashReportingOptOut(optOut: true) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(remote.invocations, [.updateCrashReportingOptOut(optOut: true)])
    }

    /// Verifies that `updateCrashReportingOptOut` relays a remote failure, so callers can keep the local value untouched.
    ///
    @MainActor
    func test_updateCrashReportingOptOut_when_remote_fails_then_returns_failure() {
        // Given
        let remote = MockAccountRemote()
        remote.whenUpdatingCrashReportingOptOut(thenReturn: .failure(NetworkError.notFound()))
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AccountAction.updateCrashReportingOptOut(optOut: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - AccountAction.synchronizeSites

    /// Verifies that `synchronizeSites` returns an error, whenever there is no backend reply.
    ///
    @MainActor
    func test_synchronizeSites_returns_error_on_empty_response() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<SiteSynchronizationResult, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `synchronizeSites` effectively persists any retrieved sites when all sites have Jetpack-the-plugin.
    ///
    @MainActor
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
        let result: Result<SiteSynchronizationResult, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites { result in
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

    @MainActor
    func test_upsertStoredSitesInBackground_when_site_synchronizations_are_cancelled_then_does_not_update_stored_sites() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let cachedSiteID = Int64(1)
        let responseSiteID = Int64(2)
        storageManager.insertSampleSite(readOnlySite: Site.fake().copy(siteID: cachedSiteID))

        // When
        store.cancelSiteSynchronizations()
        let wasApplied: Bool = waitFor { promise in
            store.upsertStoredSitesInBackground(readOnlySites: [Site.fake().copy(siteID: responseSiteID)]) { wasApplied in
                promise(wasApplied)
            }
        }

        // Then
        XCTAssertFalse(wasApplied)
        XCTAssertNotNil(viewStorage.loadSite(siteID: cachedSiteID))
        XCTAssertNil(viewStorage.loadSite(siteID: responseSiteID))
    }

    @MainActor
    func test_cancelSiteSynchronizations_when_requests_are_pending_then_completes_each_once_without_cached_fallback() {
        let site = Site.fake().copy(siteID: 123, url: "https://example.com", isJetpackThePluginInstalled: true)
        storageManager.insertSampleSite(readOnlySite: site)
        for responseArrivesBeforeCancellation in [false, true] {
            // Given
            let remote = MockAccountRemote()
            let response = PassthroughSubject<Result<[Networking.Site], Error>, Never>()
            remote.loadSitesPublisher = response.eraseToAnyPublisher()
            let store = AccountStore(dispatcher: Dispatcher(), storageManager: storageManager, network: network, remote: remote)
            var errors: [Error?] = []

            // When
            waitFor { promise in
                store.onAction(AccountAction.synchronizeSites { errors.append($0.failure) })
                store.onAction(AccountAction.synchronizeSitesAndReturnSelectedSiteInfo(siteAddress: site.url) { errors.append($0.failure) })
                store.onAction(AccountAction.loadAndSynchronizeSite(siteID: site.siteID, forcedUpdate: true, shouldSynchronize: true) {
                    errors.append($0.failure)
                })
                if responseArrivesBeforeCancellation {
                    response.send(.success([site]))
                }
                store.cancelSiteSynchronizations()
                store.cancelSiteSynchronizations()
                response.send(.success([]))
                // Let any storage completions queued before cancellation run too.
                DispatchQueue.main.async { promise(()) }
            }

            // Then
            XCTAssertEqual(errors.count, 3)
            XCTAssertTrue(errors.allSatisfy { $0 is CancellationError })
            XCTAssertNotNil(viewStorage.loadSite(siteID: site.siteID))
        }
    }

    /// Verifies that `synchronizeSites` effectively persists a Jetpack Connection Package site and a Jetpack site.
    ///
    @MainActor
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
                                                                                                     url: "http://example.com")))
        remote.whenCheckingIfWooCommerceIsActive(siteID: siteIDOfJCPSite, thenReturn: .success(true))
        let mockProcessor = MockActionsProcessor()
        dispatcher.register(processor: mockProcessor, for: AppSettingsAction.self)

        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        // When
        let result: Result<SiteSynchronizationResult, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites { result in
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
        XCTAssertEqual(jcpSite.url, "https://example.com")
        XCTAssertTrue(jcpSite.isWooCommerceActive?.boolValue == true)
        let action = try XCTUnwrap(mockProcessor.receivedActions.first as? AppSettingsAction)
        guard case let .setHTTPSConfigurationUpdateRequired(persistedSiteID, required) = action else {
            return XCTFail("Expected HTTPS configuration requirement action")
        }
        XCTAssertEqual(persistedSiteID, siteIDOfJCPSite)
        XCTAssertTrue(required)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self, matching: jetpackSitePredicate), 1)
        let jetpackSite = try XCTUnwrap(viewStorage.firstObject(ofType: Storage.Site.self, matching: jetpackSitePredicate))
        XCTAssertEqual(jetpackSite.siteID, siteIDOfJetpackSite)
    }

    /// Verifies that `synchronizeSites` effectively persists a Jetpack Connection Package site without any changes when WP site settings request fails.
    ///
    @MainActor
    func test_synchronizeSites_persists_a_jetpack_cp_site_without_any_changes_when_wp_settings_request_fails() throws {
        // Given
        let siteID = Int64(255)
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: siteID,
                             name: "old name",
                             description: "old description",
                             url: "oldurl",
                             isJetpackThePluginInstalled: false,
                             isJetpackConnected: true,
                             isWooCommerceActive: false)
        ])
        remote.whenFetchingWordPressSiteSettings(siteID: siteID, thenReturn: .failure(NetworkError.timeout()))
        remote.whenCheckingIfWooCommerceIsActive(siteID: siteID, thenReturn: .success(true))

        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        // When
        let result: Result<SiteSynchronizationResult, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites { result in
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
        XCTAssertTrue(jcpSite.isWooCommerceActive?.boolValue == false)
    }

    /// Verifies that `synchronizeSites` persists a Jetpack Connection Package site without any changes when WC site settings request fails.
    ///
    @MainActor
    func test_synchronizeSites_persists_a_jetpack_cp_site_without_any_changes_when_wc_settings_request_fails() throws {
        // Given
        let siteID = Int64(255)
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: siteID,
                             name: "old name",
                             description: "old description",
                             url: "oldurl",
                             isJetpackThePluginInstalled: false,
                             isJetpackConnected: true,
                             isWooCommerceActive: false)
        ])
        remote.whenFetchingWordPressSiteSettings(siteID: siteID, thenReturn: .success(.init(name: "new name",
                                                                                                     description: "new description",
                                                                                                     url: "newurl")))
        remote.whenCheckingIfWooCommerceIsActive(siteID: siteID, thenReturn: .failure(NetworkError.timeout()))

        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        // When
        let result: Result<SiteSynchronizationResult, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites { result in
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
        XCTAssertEqual(jcpSite.name, "old name")
        XCTAssertEqual(jcpSite.tagline, "old description")
        XCTAssertEqual(jcpSite.url, "oldurl")
        XCTAssertTrue(jcpSite.isWooCommerceActive?.boolValue == false)
        XCTAssertFalse(jcpSite.isJetpackThePluginInstalled)
        XCTAssertTrue(jcpSite.isJetpackConnected)
    }

    /// Verifies that `synchronizeSites` deletes storage sites that do not exist remotely anymore.
    ///
    @MainActor
    func test_synchronizeSites_deletes_sites_that_do_not_exist_remotely() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let siteIDInStorageOnly = Int64(127)
        storageManager.insertSampleSite(readOnlySite: Site.fake().copy(siteID: siteIDInStorageOnly))
        network.simulateResponse(requestUrlSuffix: "me/sites", filename: "sites")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 1)
        XCTAssertNotNil(viewStorage.loadSite(siteID: siteIDInStorageOnly))

        // When
        let result: Result<SiteSynchronizationResult, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites { result in
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

    @MainActor
    func test_synchronizeSites_returns_authoritative_empty_site_ids_and_deletes_cached_sites() throws {
        // Given
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([])
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        storageManager.insertSampleSite(readOnlySite: Site.fake().copy(siteID: 127))

        // When
        let result: Result<SiteSynchronizationResult, Error> = waitFor { promise in
            store.onAction(AccountAction.synchronizeSites { result in
                promise(result)
            })
        }

        // Then
        let synchronizationResult = try result.get()
        XCTAssertEqual(synchronizationResult.siteIDs, [])
        XCTAssertNil(viewStorage.loadSite(siteID: 127))
    }

    @MainActor
    func test_synchronizeSites_when_preserving_site_then_deletes_only_other_missing_sites() throws {
        // Given
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([])
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        storageManager.insertSampleSite(readOnlySite: Site.fake().copy(siteID: 123))
        storageManager.insertSampleSite(readOnlySite: Site.fake().copy(siteID: 456))

        // When
        let result: Result<SiteSynchronizationResult, Error> = waitFor { promise in
            store.onAction(AccountAction.synchronizeSites(preservingSiteID: 123, onCompletion: promise))
        }

        // Then
        XCTAssertEqual(try result.get().siteIDs, [])
        XCTAssertNotNil(viewStorage.loadSite(siteID: 123))
        XCTAssertNil(viewStorage.loadSite(siteID: 456))
    }

    /// Verifies that `synchronizeSites` deletes the selected site after a successful response omits it.
    ///
    @MainActor
    func test_synchronizeSites_deletes_selected_site_that_does_not_exist_remotely() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let selectedSiteID = Int64(127)
        storageManager.insertSampleSite(readOnlySite: Site.fake().copy(siteID: selectedSiteID))
        network.simulateResponse(requestUrlSuffix: "me/sites", filename: "sites")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 1)
        XCTAssertNotNil(viewStorage.loadSite(siteID: selectedSiteID))

        // When
        let result: Result<SiteSynchronizationResult, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        // `sites.json` contains 2 sites that do not match `selectedSiteID`.
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 2)
        XCTAssertNil(viewStorage.loadSite(siteID: selectedSiteID))
    }

    /// Verifies that `synchronizeSites` returns `false` for JCP sites presence when all sites have Jetpack-the-plugin.
    ///
    @MainActor
    func test_synchronizeSites_returns_false_when_all_sites_have_jetpack_plugin() throws {
        // Given
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: 1, isJetpackThePluginInstalled: true, isJetpackConnected: true),
            Site.fake().copy(siteID: 2, isJetpackThePluginInstalled: true, isJetpackConnected: true)
        ])
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<SiteSynchronizationResult, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let synchronizationResult = try XCTUnwrap(result.get())
        XCTAssertFalse(synchronizationResult.containsJetpackConnectionPackageSites)
    }

    /// Verifies that `synchronizeSites` returns `true` when one site is JCP.
    ///
    @MainActor
    func test_synchronizeSites_returns_true_when_one_site_is_jcp() throws {
        // Given
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: 1, isJetpackThePluginInstalled: true, isJetpackConnected: true),
            Site.fake().copy(siteID: 2, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        ])
        remote.whenCheckingIfWooCommerceIsActive(siteID: 2, thenReturn: .success(true))
        remote.whenFetchingWordPressSiteSettings(siteID: 2, thenReturn: .failure(NetworkError.notFound()))

        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<SiteSynchronizationResult, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let synchronizationResult = try XCTUnwrap(result.get())
        XCTAssertTrue(synchronizationResult.containsJetpackConnectionPackageSites)
    }

    /// Verifies that `synchronizeSites` effectively persists a site with Blaze properties from the remote.
    ///
    @MainActor
    func test_synchronizeSites_effectively_persists_site_with_blaze_properties() throws {
        // Given
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: 134, canBlaze: true, isAdmin: true)
        ])
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        // When
        let result: Result<SiteSynchronizationResult, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSites { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadSites])

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 1)
        let site = try XCTUnwrap(viewStorage.loadSite(siteID: 134))
        XCTAssertTrue(site.canBlaze)
        XCTAssertTrue(site.isAdmin)
    }

    // MARK: - AccountAction.synchronizeSitesAndReturnSelectedSiteInfo

    @MainActor
    func test_synchronizeSitesAndReturnSelectedSiteInfo_effectively_persists_retrieved_sites_and_returns_the_matching_site() throws {
        // Given
        let expectedSiteURL = "https://example.com"
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: 1, isJetpackThePluginInstalled: true, isJetpackConnected: true),
            Site.fake().copy(siteID: 2, isJetpackThePluginInstalled: false, isJetpackConnected: true),
            Site.fake().copy(siteID: 3, url: expectedSiteURL, isJetpackThePluginInstalled: true, isJetpackConnected: true)
        ])
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        // When
        let result: Result<SelectedSiteSynchronizationResult, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSitesAndReturnSelectedSiteInfo(siteAddress: expectedSiteURL) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadSites])

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 3)
        let site = try result.get().site
        XCTAssertEqual(site.url, expectedSiteURL)
    }

    @MainActor
    func test_synchronizeSitesAndReturnSelectedSiteInfo_throws_not_found_error_if_no_matching_site_is_found() {
        // Given
        let expectedSiteURL = "https://example.com"
        let remote = MockAccountRemote()
        remote.loadSitesResult = .success([
            Site.fake().copy(siteID: 1, isJetpackThePluginInstalled: true, isJetpackConnected: true),
            Site.fake().copy(siteID: 2, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        ])
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        // When
        let result: Result<SelectedSiteSynchronizationResult, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSitesAndReturnSelectedSiteInfo(siteAddress: expectedSiteURL) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadSites])

        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)
        XCTAssertEqual(result.failure as? NetworkError, NetworkError.notFound())
    }

    @MainActor
    func test_synchronizeSitesAndReturnSelectedSiteInfo_relays_error_when_loadSites_fails() {
        // Given
        let expectedSiteURL = "https://example.com"
        let expectedError = NetworkError.timeout()
        let remote = MockAccountRemote()
        remote.loadSitesResult = .failure(expectedError)
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        // When
        let result: Result<SelectedSiteSynchronizationResult, Error> = waitFor { promise in
            let action = AccountAction.synchronizeSitesAndReturnSelectedSiteInfo(siteAddress: expectedSiteURL) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadSites])

        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
    }

    // MARK: - AccountAction.loadAccount

    @MainActor
    func test_loadAccount_returns_expected_account() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Account.self), 0)
        store.upsertStoredAccount(readOnlyAccount: sampleAccountPristine(), onCompletion: {})
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
        //XCTAssertEqual(account, sampleAccountPristine())
        assertEqual(account, sampleAccountPristine())
    }

    @MainActor
    func test_loadAccount_returns_nil_for_unknown_account() {
        // Given
        let store = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Account.self), 0)
        store.upsertStoredAccount(readOnlyAccount: sampleAccountPristine(), onCompletion: {})
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

    @MainActor
    func test_loadAndSynchronizeSite_returns_site_already_in_storage_without_making_network_request_if_forcedUpdate_is_false() throws {
        // Given
        let network = MockNetwork()
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        let siteID = Int64(999)
        let sampleSite = sampleSitePristine().copy(siteID: siteID)
        let group = DispatchGroup()
        group.enter()
        accountStore.upsertStoredSitesInBackground(readOnlySites: [sampleSite]) { _ in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 1)
            group.leave()
        }

        // When
        let result: Result<SiteLoadResult, Error> = waitFor { promise in
            group.notify(queue: .main) {
                let action = AccountAction.loadAndSynchronizeSite(siteID: siteID, forcedUpdate: false, shouldSynchronize: true) { result in
                    XCTAssertTrue(Thread.isMainThread)
                    promise(result)
                }
                accountStore.onAction(action)
            }
        }

        // Then
        let site = try XCTUnwrap(try result.get().site)
        XCTAssertEqual(site, sampleSite)
        XCTAssertEqual(network.requestsForResponseData.count, 0)
    }

    @MainActor
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
        accountStore.upsertStoredSitesInBackground(readOnlySites: [sampleSite]) { _ in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 1)
            group.leave()
        }

        // When
        let result: Result<SiteLoadResult, Error> = waitFor { promise in
            group.notify(queue: .main) {
                let action = AccountAction.loadAndSynchronizeSite(siteID: siteIDInSimulatedResponse, forcedUpdate: true, shouldSynchronize: true) { result in
                    XCTAssertTrue(Thread.isMainThread)
                    promise(result)
                }
                accountStore.onAction(action)
            }
        }

        // Then
        let site = try XCTUnwrap(try result.get().site)
        XCTAssertEqual(site.isWooCommerceActive, true) // the value in `sites.json` - not the one in storage.
        XCTAssertEqual(network.requestsForResponseData.count, 3)
    }

    @MainActor
    func test_loadAndSynchronizeSite_returns_unknown_site_error_after_syncing_failure() throws {
        // Given
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let group = DispatchGroup()
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        group.enter()
        accountStore.upsertStoredSitesInBackground(readOnlySites: [sampleSitePristine()]) { _ in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 1)
            group.leave()
        }

        // When
        let result: Result<SiteLoadResult, Error> = waitFor { promise in
            group.notify(queue: .main) {
                let action = AccountAction.loadAndSynchronizeSite(siteID: 9999, forcedUpdate: false, shouldSynchronize: true) { result in
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

    @MainActor
    func test_loadAndSynchronizeSite_does_not_request_wpcom_sites_when_synchronization_is_disabled() throws {
        // Given
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<SiteLoadResult, Error> = waitFor { promise in
            accountStore.onAction(AccountAction.loadAndSynchronizeSite(siteID: 9999,
                                                                        forcedUpdate: true,
                                                                        shouldSynchronize: false) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertEqual(result.failure as? SynchronizeSiteError, .unknownSite)
        XCTAssertTrue(network.requestsForResponseData.isEmpty)
    }

    @MainActor
    func test_loadAndSynchronizeSite_returns_site_after_syncing_success() throws {
        // Given
        let network = MockNetwork()
        network.simulateResponse(requestUrlSuffix: "me/sites", filename: "sites")
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let group = DispatchGroup()
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Site.self), 0)

        group.enter()
        accountStore.upsertStoredSitesInBackground(readOnlySites: [sampleSitePristine()]) { _ in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Site.self), 1)
            group.leave()
        }

        // When
        // The site ID value is in `sites.json` used in the mock network.
        let siteIDInSimulatedResponse = Int64(1112233334444555)
        let result: Result<SiteLoadResult, Error> = waitFor { promise in
            group.notify(queue: .main) {
                let action = AccountAction.loadAndSynchronizeSite(siteID: siteIDInSimulatedResponse,
                                                                  forcedUpdate: true,
                                                                  shouldSynchronize: true) { result in
                    XCTAssertTrue(Thread.isMainThread)
                    promise(result)
                }
                accountStore.onAction(action)
            }
        }

        // Then
        let site = try XCTUnwrap(try result.get().site)
        XCTAssertEqual(site.siteID, siteIDInSimulatedResponse)
    }

    @MainActor
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
        remote.whenFetchingWordPressSiteSettings(siteID: siteIDOfJCPSite, thenReturn: .failure(NetworkError.notFound()))
        let accountStore = AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let _: Void = waitFor { promise in
            let action = AccountAction.loadAndSynchronizeSite(siteID: 123, forcedUpdate: true, shouldSynchronize: true) { _ in
                promise(())
            }
            accountStore.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations,
                       [.loadSites, .checkIfWooCommerceIsActive(siteID: siteIDOfJCPSite), .fetchWordPressSiteSettings(siteID: siteIDOfJCPSite)])
    }

    @MainActor
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
            let action = AccountAction.loadAndSynchronizeSite(siteID: 123, forcedUpdate: true, shouldSynchronize: true) { _ in
                promise(())
            }
            accountStore.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadSites])
    }

    @MainActor
    func test_disconnectFromSocialService_returns_success_on_dotcom_remote_success() throws {
        // Given
        let network = MockNetwork()
        let accountRemote = MockAccountRemote()
        accountRemote.whenClosingAccount(thenReturn: .success(()))
        let accountStore = AccountStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: accountRemote)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AccountAction.closeAccount { result in
                promise(result)
            }
            accountStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    @MainActor
    func test_disconnectFromSocialService_returns_failure_on_dotcom_remote_failure() throws {
        // Given
        let network = MockNetwork()
        let accountRemote = MockAccountRemote()
        let error = NSError(domain: "disconnect", code: 134)
        accountRemote.whenClosingAccount(thenReturn: .failure(error))
        let accountStore = AccountStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: accountRemote)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = AccountAction.closeAccount { result in
                promise(result)
            }
            accountStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as NSError?, error)
    }

    // MARK: - updateNotificationSettings

    @MainActor
    func test_updateNotificationSettings_returns_success_upon_success() {
        // Given
        let network = MockNetwork()
        let accountRemote = MockAccountRemote()
        accountRemote.whenUpdatingNotificationSettings(thenReturn: .success(()))
        let accountStore = AccountStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: accountRemote)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let notificationSettings = NotificationSettings(deviceID: 132, enabledSites: [23], disabledSites: [44, 66])
            let action = AccountAction.updateNotificationSettings(notificationSettings: notificationSettings) { result in
                promise(result)
            }
            accountStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    @MainActor
    func test_updateNotificationSettings_relays_error_upon_failure() {
        // Given
        let network = MockNetwork()
        let accountRemote = MockAccountRemote()
        let error = NSError(domain: "notifications", code: 33)
        accountRemote.whenUpdatingNotificationSettings(thenReturn: .failure(error))
        let accountStore = AccountStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: accountRemote)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let notificationSettings = NotificationSettings(deviceID: 132, enabledSites: [23], disabledSites: [44, 66])
            let action = AccountAction.updateNotificationSettings(notificationSettings: notificationSettings) { result in
                promise(result)
            }
            accountStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as NSError?, error)
    }

    // MARK: - loadNotificationSettings

    @MainActor
    func test_loadNotificationSettings_returns_success_upon_success() throws {
        // Given
        let network = MockNetwork()
        let accountRemote = MockAccountRemote()
        let deviceID: Int64 = 115
        let settings = NotificationSettings(blogs: [
            .init(blogID: 113, devices: [.init(deviceID: deviceID, newComment: true, storeOrder: true)]),
            .init(blogID: 72, devices: [.init(deviceID: deviceID, newComment: false, storeOrder: true)])
        ])
        accountRemote.whenLoadingNotificationSettings(thenReturn: .success(settings))
        let accountStore = AccountStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: accountRemote)

        // When
        let result: Result<NotificationSettings, Error> = waitFor { promise in
            let action = AccountAction.loadNotificationSettings(deviceID: deviceID) { result in
                promise(result)
            }
            accountStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(try result.get(), settings)
    }

    @MainActor
    func test_loadNotificationSettings_relays_error_upon_failure() {
        // Given
        let network = MockNetwork()
        let accountRemote = MockAccountRemote()
        let error = NSError(domain: "notifications", code: 33)
        accountRemote.whenLoadingNotificationSettings(thenReturn: .failure(error))
        let accountStore = AccountStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: accountRemote)

        // When
        let result: Result<NotificationSettings, Error> = waitFor { promise in
            let action = AccountAction.loadNotificationSettings(deviceID: 11) { result in
                promise(result)
            }
            accountStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as NSError?, error)
    }
}

// MARK: - Private Methods
//
private extension AccountStoreTests {

    /// Verifies that the Storage.Account fields match with the specified Networking.Account.
    ///
    @MainActor
    func compare(storageAccount: Storage.Account, remoteAccount: Networking.Account) {
        XCTAssertEqual(storageAccount.userID, remoteAccount.userID)
        XCTAssertEqual(storageAccount.displayName, remoteAccount.displayName)
        XCTAssertEqual(storageAccount.email, remoteAccount.email)
        XCTAssertEqual(storageAccount.username, remoteAccount.username)
        XCTAssertEqual(storageAccount.gravatarUrl, remoteAccount.gravatarUrl)
    }

    /// Sample Account: Mark I
    ///
    @MainActor
    func sampleAccountPristine() -> Networking.Account {
        return Account(userID: 1234,
                       displayName: "Sample",
                       email: "email@email.com",
                       username: "Username!",
                       gravatarUrl: "https://automattic.com/superawesomegravatar.png")
    }

    /// Sample Account: Mark II
    ///
    @MainActor
    func sampleAccountUpdate() -> Networking.Account {
        return Account(userID: 1234,
                       displayName: "Yosemite",
                       email: "yosemite@yosemite.com",
                       username: "YOLO",
                       gravatarUrl: "https://automattic.com/yosemite.png")
    }

    @MainActor
    func sampleAccountSettings() -> Networking.AccountSettings {
        return AccountSettings(userID: 10,
                               tracksOptOut: true,
                               crashReportingOptOut: nil,
                               firstName: nil,
                               lastName: nil)
    }

    /// Sample Site
    ///
    @MainActor
    func sampleSitePristine() -> Networking.Site {
        return Site.fake()
    }
}
