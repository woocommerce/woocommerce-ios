import XCTest
@testable import Yosemite
@testable import Networking
@testable import NetworkingCore
import TestKit

final class WordPressSiteStoreTests: XCTestCase {
    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock Dispatcher
    ///
    private var dispatcher: Dispatcher!

    private let sampleSiteURL = "https://test.com"

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        network = MockNetwork()
        WordPressRESTAPIRootCache.shared.setRoot("https://test.com/wp-json/", for: sampleSiteURL)
    }

    override func tearDown() {
        WordPressRESTAPIRootCache.shared.reset()
        super.tearDown()
    }

    @MainActor
    func test_fetchSiteInfo_returns_correct_site() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "wp-json/", filename: "wordpress-site-info")
        let store = WordPressSiteStore(network: network, dispatcher: dispatcher)

        // When
        let result: Result<Site, Error> = try await waitForCompletion { completion in
            let action = WordPressSiteAction.fetchSiteInfo(siteURL: self.sampleSiteURL, completion: completion)
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let site = try result.get()
        XCTAssertEqual(site.name, "My WordPress Site")
        XCTAssertEqual(site.description, "Just another WordPress site")
        XCTAssertEqual(site.url, "https://test.com")
        XCTAssertEqual(site.timezone, "")
        XCTAssertEqual(site.siteID, -1)
        XCTAssertEqual(site.gmtOffset, 0)
        XCTAssertEqual(site.adminURL, "https://test.com/wp-admin/")
        XCTAssertEqual(site.loginURL, "https://test.com/wp-login.php")
        XCTAssertFalse(site.isWooCommerceActive)
        XCTAssertFalse(site.isJetpackConnected)
        XCTAssertFalse(site.isJetpackThePluginInstalled)
    }

    @MainActor
    func test_fetchSiteInfo_relays_error_properly() async throws {
        // Given
        network.simulateError(requestUrlSuffix: "wp-json/", error: NetworkError.notFound())
        let store = WordPressSiteStore(network: network, dispatcher: dispatcher)

        // When
        let result: Result<Site, Error> = try await waitForCompletion { completion in
            let action = WordPressSiteAction.fetchSiteInfo(siteURL: self.sampleSiteURL, completion: completion)
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertTrue(result.failure is NetworkError)
    }

    @MainActor
    func test_fetchApplicationPasswordAuthorizationURL_returns_nil_authorization_url_if_application_password_is_not_available() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "wp-json/", filename: "wordpress-site-info")
        let store = WordPressSiteStore(network: network, dispatcher: dispatcher)

        // When
        let result: Result<ApplicationPasswordAuthorization?, Error> = try await waitForCompletion { completion in
            let action = WordPressSiteAction.fetchApplicationPasswordAuthorizationURL(siteURL: self.sampleSiteURL, completion: completion)
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let url = try result.get()
        XCTAssertNil(url)
    }

    @MainActor
    func test_fetchApplicationPasswordAuthorizationURL_when_approval_page_is_on_same_host_then_returns_it_without_approval_site() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "//example.com/wp-json/", filename: "wordpress-site-info-with-auth-url")
        let store = makeStore()

        // When
        let result = try await fetchAuthorization(siteURL: "https://example.com", store: store)

        // Then
        let authorization = try result.get()
        XCTAssertEqual(authorization?.url.absoluteString, "https://example.com/wp-admin/authorize-application.php")
        XCTAssertNil(authorization?.approvalSiteURL)
        XCTAssertEqual(network.requestsForResponseData.count, 1)
    }

    @MainActor
    func test_fetchApplicationPasswordAuthorizationURL_when_store_is_in_subfolder_then_returns_it_without_approval_site() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "//test.com/shop/wp-json/", filename: "wordpress-site-info-with-subfolder-auth-url")
        let store = makeStore()

        // When
        let result = try await fetchAuthorization(siteURL: "https://test.com/shop", store: store)

        // Then
        let authorization = try result.get()
        XCTAssertEqual(authorization?.url.absoluteString, "https://test.com/shop/wp-admin/authorize-application.php")
        XCTAssertNil(authorization?.approvalSiteURL)
        XCTAssertEqual(network.requestsForResponseData.count, 1)
    }

    @MainActor
    func test_fetchApplicationPasswordAuthorizationURL_when_other_host_reports_store_as_home_then_returns_it_with_approval_site() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "//test.com/wp-json/", filename: "wordpress-site-info-with-foreign-auth-url")
        network.simulateResponse(requestUrlSuffix: "//wp.test.com/wp-json/", filename: "wordpress-site-info")
        let store = makeStore()

        // When
        let result = try await fetchAuthorization(siteURL: sampleSiteURL, store: store)

        // Then
        let authorization = try result.get()
        XCTAssertEqual(authorization?.url.absoluteString, "https://wp.test.com/wp-admin/authorize-application.php")
        XCTAssertEqual(authorization?.approvalSiteURL, "https://wp.test.com")
        XCTAssertEqual(network.requestsForResponseData.count, 2)
    }

    @MainActor
    func test_fetchApplicationPasswordAuthorizationURL_when_other_host_reports_another_home_then_fails_with_site_mismatch() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "//test.com/wp-json/", filename: "wordpress-site-info-with-foreign-auth-url")
        network.simulateResponse(requestUrlSuffix: "//wp.test.com/wp-json/", filename: "wordpress-site-info-with-auth-url")
        let store = makeStore()

        // When
        let result = try await fetchAuthorization(siteURL: sampleSiteURL, store: store)

        // Then
        XCTAssertEqual(result.failure as? ApplicationPasswordAuthorizationError, .siteMismatch)
    }

    @MainActor
    func test_fetchApplicationPasswordAuthorizationURL_when_other_host_home_fetch_fails_then_fails_with_site_mismatch() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "//test.com/wp-json/", filename: "wordpress-site-info-with-foreign-auth-url")
        network.simulateError(requestUrlSuffix: "//wp.test.com/wp-json/", error: NetworkError.notFound())
        let store = makeStore()

        // When
        let result = try await fetchAuthorization(siteURL: sampleSiteURL, store: store)

        // Then
        XCTAssertEqual(result.failure as? ApplicationPasswordAuthorizationError, .siteMismatch)
    }

    @MainActor
    func test_fetchApplicationPasswordAuthorizationURL_when_listed_url_is_not_an_approval_page_then_fails_with_site_mismatch() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "//test.com/wp-json/", filename: "wordpress-site-info-with-non-approval-auth-url")
        let store = makeStore()

        // When
        let result = try await fetchAuthorization(siteURL: sampleSiteURL, store: store)

        // Then
        XCTAssertEqual(result.failure as? ApplicationPasswordAuthorizationError, .siteMismatch)
        XCTAssertEqual(network.requestsForResponseData.count, 1)
    }

    @MainActor
    func test_fetchApplicationPasswordAuthorizationURL_relays_error_properly() async throws {
        // Given
        network.simulateError(requestUrlSuffix: "wp-json/", error: NetworkError.notFound())
        let store = WordPressSiteStore(network: network, dispatcher: dispatcher)

        // When
        let result: Result<ApplicationPasswordAuthorization?, Error> = try await waitForCompletion { completion in
            let action = WordPressSiteAction.fetchApplicationPasswordAuthorizationURL(siteURL: self.sampleSiteURL, completion: completion)
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertTrue(result.failure is NetworkError)
    }

    @MainActor
    func test_fetchPageList_returns_correct_page_list() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "wp-json/wp/v2/pages?_fields=id,title,link", filename: "wp-page-list-success")
        let store = WordPressSiteStore(network: network, dispatcher: dispatcher)

        // When
        let result: Result<[WordPressPage], Error> = try await waitForCompletion { completion in
            let action = WordPressSiteAction.fetchPageList(siteURL: self.sampleSiteURL, completion: completion)
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let list = try result.get()
        XCTAssertEqual(list, [
            .init(id: 21, title: "Cart", link: "https://example.com/cart/"),
            .init(id: 20, title: "Shop", link: "https://example.com/shop/"),
            .init(id: 6, title: "Blog", link: "https://example.com/blog/")
        ])
    }

    @MainActor
    func test_fetchPageList_relays_error_properly() async throws {
        // Given
        network.simulateError(requestUrlSuffix: "wp-json/wp/v2/pages?_fields=id,title,link", error: NetworkError.notFound())
        let store = WordPressSiteStore(network: network, dispatcher: dispatcher)

        // When
        let result: Result<[WordPressPage], Error> = try await waitForCompletion { completion in
            let action = WordPressSiteAction.fetchPageList(siteURL: self.sampleSiteURL, completion: completion)
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertTrue(result.failure is NetworkError)
    }
}

private extension WordPressSiteStoreTests {
    /// Skips REST API discovery, so each site is fetched at its default `wp-json` root.
    func makeStore() -> WordPressSiteStore {
        let remote = WordPressSiteRemote(network: network, apiRootCache: WordPressRESTAPIRootCache.shared, discoverRESTAPIRoot: { _ in nil })
        return WordPressSiteStore(remote: remote, dispatcher: dispatcher)
    }

    @MainActor
    func fetchAuthorization(siteURL: String, store: WordPressSiteStore) async throws -> Result<ApplicationPasswordAuthorization?, Error> {
        try await waitForCompletion { completion in
            store.onAction(WordPressSiteAction.fetchApplicationPasswordAuthorizationURL(siteURL: siteURL, completion: completion))
        }
    }
}
