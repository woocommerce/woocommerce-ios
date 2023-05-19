import Combine
import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class StoreCreationStatusCheckerTests: XCTestCase {
    private var sut: StoreCreationStatusChecker!
    private var stores: MockStoresManager!
    private var siteReadySubscription: AnyCancellable?

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        sut = StoreCreationStatusChecker(jetpackCheckRetryInterval: 0, stores: stores)
    }

    override func tearDown() {
        siteReadySubscription = nil
        sut = nil
        stores = nil
        super.tearDown()
    }

    func test_waitForSiteToBeReady_returns_site_when_plugins_are_active() throws {
        // Given
        let site = Site.fake().copy(name: "testing")
        mockPluginsActive(result: .success(true))
        mockSyncSite(result: .success(site))

        // When
        waitFor { promise in
            self.siteReadySubscription = self.sut.waitForSiteToBeReady(siteID: 122)
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        XCTFail()
                    }
                } receiveValue: { syncedSite in
                    // Then
                    XCTAssertEqual(syncedSite, site)
                    promise(())
                }
        }
    }

    func test_waitForSiteToBeReady_returns_error_when_failing_to_check_plugins() throws {
        // Given
        let pluginsError = NSError(domain: "plugins inactive", code: 0)
        mockPluginsActive(result: .failure(pluginsError))
        mockSyncSite(result: .success(.fake()))

        // When
        waitFor { promise in
            self.siteReadySubscription = self.sut.waitForSiteToBeReady(siteID: 122)
                .sink { completion in
                    switch completion {
                    case .finished:
                        XCTFail()
                    case .failure(let error):
                        // Then
                        XCTAssertEqual(error as NSError, pluginsError)
                        promise(())
                    }
                } receiveValue: { site in
                    XCTFail()
                }
        }
    }

    func test_waitForSiteToBeReady_returns_error_when_failing_to_sync_site() throws {
        // Given
        let syncSiteError = NSError(domain: "sync site", code: 0)
        mockPluginsActive(result: .success(true))
        mockSyncSite(result: .failure(syncSiteError))

        // When
        waitFor { promise in
            self.siteReadySubscription = self.sut.waitForSiteToBeReady(siteID: 122)
                .sink { completion in
                    switch completion {
                    case .finished:
                        XCTFail()
                    case .failure(let error):
                        // Then
                        XCTAssertEqual(error as NSError, syncSiteError)
                        promise(())
                    }
                } receiveValue: { site in
                    XCTFail()
                }
        }
    }

    func test_waitForSiteToBeReady_returns_error_when_plugins_are_not_active() throws {
        // Given
        mockPluginsActive(result: .success(false))
        mockSyncSite(result: .success(.fake()))

        // When
        waitFor { promise in
            self.siteReadySubscription = self.sut.waitForSiteToBeReady(siteID: 122)
                .sink { completion in
                    switch completion {
                    case .finished:
                        XCTFail()
                    case .failure(let error):
                        // Then
                        XCTAssertEqual(error as? StoreCreationError, .newSiteIsNotJetpackSite)
                        promise(())
                    }
                } receiveValue: { site in
                    XCTFail()
                }
        }
    }
}

private extension StoreCreationStatusCheckerTests {
    func mockSyncSite(result: Result<Site, Error>) {
        stores.whenReceivingAction(ofType: SiteAction.self) { action in
            guard case let .syncSite(_, completion) = action else {
                return
            }
            completion(result)
        }
    }

    func mockPluginsActive(result: Result<Bool, Error>) {
        stores.whenReceivingAction(ofType: SitePluginAction.self) { action in
            guard case let .arePluginsActive(_, _, completion) = action else {
                return
            }
            completion(result)
        }
    }
}
