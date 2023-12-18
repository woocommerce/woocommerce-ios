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
        sut = StoreCreationStatusChecker(jetpackCheckRetryInterval: 0, storeName: "Wind", stores: stores)
    }

    override func tearDown() {
        siteReadySubscription = nil
        sut = nil
        stores = nil
        super.tearDown()
    }

    func test_waitForSiteToBeReady_returns_site_when_site_has_all_necessary_properties() throws {
        // Given
        let site = Site.fake().copy(name: "testing",
                                    isJetpackThePluginInstalled: true,
                                    isJetpackConnected: true,
                                    isWooCommerceActive: true,
                                    isWordPressComStore: true)
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

    func test_waitForSiteToBeReady_returns_newSiteIsNotJetpackSite_error_when_site_is_missing_jetpack_properties() throws {
        // Given
        let sitesMissingANecessaryProperty = [
            Site.fake().copy(name: "testing",
                             isJetpackThePluginInstalled: false,
                             isJetpackConnected: true,
                             isWooCommerceActive: true,
                             isWordPressComStore: true),
            Site.fake().copy(name: "testing",
                             isJetpackThePluginInstalled: true,
                             isJetpackConnected: false,
                             isWooCommerceActive: true,
                             isWordPressComStore: true)
            ]

        for site in sitesMissingANecessaryProperty {
            mockSyncSite(result: .success(site))

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

    func test_waitForSiteToBeReady_returns_newSiteIsNotFullySynced_error_when_site_is_missing_other_necessary_properties() throws {
        // Given
        let sitesMissingANecessaryProperty = [
            Site.fake().copy(name: "testing",
                             isJetpackThePluginInstalled: true,
                             isJetpackConnected: true,
                             isWooCommerceActive: false,
                             isWordPressComStore: true),
            Site.fake().copy(name: "testing",
                             isJetpackThePluginInstalled: true,
                             isJetpackConnected: true,
                             isWooCommerceActive: true,
                             isWordPressComStore: false)
        ]

        for site in sitesMissingANecessaryProperty {
            mockSyncSite(result: .success(site))

            // When
            waitFor { promise in
                self.siteReadySubscription = self.sut.waitForSiteToBeReady(siteID: 122)
                    .sink { completion in
                        switch completion {
                        case .finished:
                            XCTFail()
                        case .failure(let error):
                            // Then
                            XCTAssertEqual(error as? StoreCreationError, .newSiteIsNotFullySynced)
                            promise(())
                        }
                    } receiveValue: { site in
                        XCTFail()
                    }
            }
        }
    }

    func test_waitForSiteToBeReady_returns_error_when_failing_to_sync_site() throws {
        // Given
        let syncSiteError = NSError(domain: "sync site", code: 0)
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
}
