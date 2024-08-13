import XCTest
import enum Networking.DotcomError
import enum Networking.SiteCreationError
import enum Networking.WordPressApiError
import struct Networking.Site
@testable import class Networking.MockNetwork
@testable import Yosemite
@testable import Storage

final class SiteStoreTests: XCTestCase {
    /// Mock Dispatcher.
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory.
    private var storageManager: MockStorageManager!

    /// Storage
    ///
    private var storage: StorageType! {
        storageManager.viewStorage
    }

    /// Convenience: returns the StorageType associated with the main thread
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Mock Network: Allows us to inject predefined responses.
    private var network: Networking.MockNetwork!

    private var remote: MockSiteRemote!
    private var store: SiteStore!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        remote = MockSiteRemote()
        store = SiteStore(remote: remote,
                          dispatcher: dispatcher,
                          storageManager: storageManager,
                          network: network)
    }

    override func tearDown() {
        store = nil
        remote = nil
        network = nil
        storageManager = nil
        dispatcher = nil
        super.tearDown()
    }

    // MARK: - `createSite`

    func test_createSite_returns_site_result_on_success() throws {
        // Given
        remote.whenCreatingSite(thenReturn: .success(
            .init(site: .init(siteID: "134",
                              name: "Salsa verde",
                              url: "https://salsa.verde/",
                              siteSlug: "salsa.verde"),
                  success: true)))

        // When
        let result = waitFor { promise in
            self.store.onAction(SiteAction.createSite(name: "Salsa",
                                                      flow: .onboarding(domain: "salsa.roja"),
                                                      completion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let siteResult = try XCTUnwrap(result.get())
        XCTAssertEqual(siteResult, .init(siteID: 134, name: "Salsa verde", url: "https://salsa.verde/", siteSlug: "salsa.verde"))
    }

    func test_createSite_returns_unsuccessful_error_on_false_success() throws {
        // Given
        remote.whenCreatingSite(thenReturn: .success(
            .init(site: .init(siteID: "134",
                              name: "Salsa verde",
                              url: "https://salsa.verde/",
                              siteSlug: "salsa.verde"),
                  // Success flag is `false` for some reason.
                  success: false)))

        // When
        let result = waitFor { promise in
            self.store.onAction(SiteAction.createSite(name: "Salsa",
                                                      flow: .onboarding(domain: "salsa.roja"),
                                                      completion: { result in
                promise(result)
            }))
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, .unsuccessful)
    }

    func test_createSite_returns_invalidDomain_error_on_Networking_domain_error() throws {
        // Given
        remote.whenCreatingSite(thenReturn: .failure(
            Networking.SiteCreationError.invalidDomain
        ))

        // When
        let result = waitFor { promise in
            self.store.onAction(SiteAction.createSite(name: "Salsa",
                                                      flow: .onboarding(domain: "salsa.roja"),
                                                      completion: { result in
                promise(result)
            }))
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, .invalidDomain)
    }

    func test_createSite_returns_domainExists_error_on_Dotcom_blog_name_exists_error() throws {
        // Given
        remote.whenCreatingSite(thenReturn: .failure(
            DotcomError.unknown(code: "blog_name_exists", message: "Sorry, that site already exists!")
        ))

        // When
        let result = waitFor { promise in
            self.store.onAction(SiteAction.createSite(name: "Salsa",
                                                      flow: .onboarding(domain: "salsa.roja"),
                                                      completion: { result in
                promise(result)
            }))
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, .domainExists)
    }

    func test_createSite_returns_invalidDomain_error_on_Dotcom_blog_name_error() throws {
        // Given
        remote.whenCreatingSite(thenReturn: .failure(
            DotcomError.unknown(code: "blog_name_only_lowercase_letters_and_numbers",
                                message: "Site names can only contain lowercase letters (a-z) and numbers.")
        ))

        // When
        let result = waitFor { promise in
            self.store.onAction(SiteAction.createSite(name: "Salsa",
                                                      flow: .onboarding(domain: "salsa.roja"),
                                                      completion: { result in
                promise(result)
            }))
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, .invalidDomain)
    }

    // MARK: - `launchSite`

    func test_launchSite_returns_success_on_success() throws {
        // Given
        remote.whenLaunchingSite(thenReturn: .success(()))

        // When
        let result = waitFor { promise in
            self.store.onAction(SiteAction.launchSite(siteID: 134) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_launchSite_returns_alreadyLaunched_error_on_already_launched_WordPressApiError() throws {
        // Given
        remote.whenLaunchingSite(thenReturn: .failure(WordPressApiError.unknown(code: "already-launched", message: "")))

        // When
        let result = waitFor { promise in
            self.store.onAction(SiteAction.launchSite(siteID: 134) { result in
                promise(result)
            })
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, .alreadyLaunched)
    }

    func test_launchSite_returns_unexpected_error_on_unauthorized_WordPressApiError() throws {
        // Given
        remote.whenLaunchingSite(thenReturn: .failure(WordPressApiError.unknown(code: "unauthorized", message: "")))

        // When
        let result = waitFor { promise in
            self.store.onAction(SiteAction.launchSite(siteID: 134) { result in
                promise(result)
            })
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, .unexpected(description: "WordPress API Error: [unauthorized] "))
    }

    // MARK: - `enableFreeTrial`

    func test_enableFreeTrial_returns_success_on_success() throws {
        // Given
        remote.whenEnablingFreeTrial(thenReturn: .success(()))

        // When
        let result = waitFor { promise in
            self.store.onAction(SiteAction.enableFreeTrial(siteID: 134) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_enableFreeTrial_returns_error_on_failure() throws {
        // Given
        remote.whenEnablingFreeTrial(thenReturn: .failure(DotcomError.unknown(code: "error", message: nil)))

        // When
        let result = waitFor { promise in
            self.store.onAction(SiteAction.enableFreeTrial(siteID: 134) { result in
                promise(result)
            })
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? DotcomError, .unknown(code: "error", message: nil))
    }

     // MARK: - `updateSiteTitle`

    func test_updateSiteTitle_returns_on_success() {
        // Given
        let siteID: Int64 = 123
        remote.whenUpdatingSiteTitle(thenReturn: .success(()))
        storeSite(Site.fake().copy(siteID: siteID, name: "Miffy"))

        // When
        let result = waitFor { promise in
            self.store.onAction(SiteAction.updateSiteTitle(siteID: siteID, title: "Test", completion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let site = viewStorage.loadSite(siteID: siteID)
        XCTAssertEqual(site?.name, "Test")
    }

    func test_updateSiteTitle_returns_error_on_failure() throws {
        // Given
        let siteID: Int64 = 123
        remote.whenUpdatingSiteTitle(thenReturn: .failure(DotcomError.unknown(code: "error", message: nil)))

        // When
        let result = waitFor { promise in
            self.store.onAction(SiteAction.updateSiteTitle(siteID: siteID, title: "Test", completion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertFalse(result.isSuccess)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? DotcomError, .unknown(code: "error", message: nil))
    }

    // MARK: - `uploadStoreProfilerAnswers`

    func test_uploadStoreProfilerAnswers_returns_success_on_success() throws {
        // Given
        remote.whenUploadingStoreProfilerAnswers(thenReturn: .success(()))

        // When
        let result = waitFor { promise in
            self.store.onAction(SiteAction.uploadStoreProfilerAnswers(siteID: 134, answers: .init(sellingStatus: nil,
                                                                                                  sellingPlatforms: "wordpress",
                                                                                                  category: "clothing_and_accessories",
                                                                                                  countryCode: "US")) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_uploadStoreProfilerAnswers_returns_error_on_failure() throws {
        // Given
        remote.whenUploadingStoreProfilerAnswers(thenReturn: .failure(DotcomError.unknown(code: "error", message: nil)))

        // When
        let result = waitFor { promise in
            self.store.onAction(SiteAction.uploadStoreProfilerAnswers(siteID: 134, answers: .init(sellingStatus: nil,
                                                                                                  sellingPlatforms: "wordpress",
                                                                                                  category: "clothing_and_accessories",
                                                                                                  countryCode: "US")) { result in
                promise(result)
            })
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? DotcomError, .unknown(code: "error", message: nil))
    }
}

private extension SiteStoreTests {
    @discardableResult
    func storeSite(_ site: Networking.Site) -> Storage.Site {
        let storedSite = storage.insertNewObject(ofType: StorageSite.self)
        storedSite.update(with: site)
        return storedSite
    }
}
