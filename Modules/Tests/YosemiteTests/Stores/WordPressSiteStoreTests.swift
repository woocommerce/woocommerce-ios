import XCTest
@testable import Yosemite
@testable import Networking

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
    }

    func test_fetchSiteInfo_returns_correct_site() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "?rest_route=/", filename: "wordpress-site-info")
        let store = WordPressSiteStore(network: network, dispatcher: dispatcher)

        // When
        let result: Result<Site, Error> = waitFor { promise in
            let action = WordPressSiteAction.fetchSiteInfo(siteURL: self.sampleSiteURL) { result in
                promise(result)
            }
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

    func test_fetchSiteInfo_relays_error_properly() throws {
        // Given
        network.simulateError(requestUrlSuffix: "?rest_route=/", error: NetworkError.notFound())
        let store = WordPressSiteStore(network: network, dispatcher: dispatcher)

        // When
        let result: Result<Site, Error> = waitFor { promise in
            let action = WordPressSiteAction.fetchSiteInfo(siteURL: self.sampleSiteURL) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertTrue(result.failure is NetworkError)
    }

    func test_fetchApplicationPasswordAuthorizationURL_returns_nil_authorization_url_if_application_password_is_not_available() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "?rest_route=/", filename: "wordpress-site-info")
        let store = WordPressSiteStore(network: network, dispatcher: dispatcher)

        // When
        let result: Result<URL?, Error> = waitFor { promise in
            let action = WordPressSiteAction.fetchApplicationPasswordAuthorizationURL(siteURL: self.sampleSiteURL) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let url = try result.get()
        XCTAssertNil(url)
    }

    func test_fetchApplicationPasswordAuthorizationURL_returns_correct_authorization_url_if_available() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "?rest_route=/", filename: "wordpress-site-info-with-auth-url")
        let store = WordPressSiteStore(network: network, dispatcher: dispatcher)

        // When
        let result: Result<URL?, Error> = waitFor { promise in
            let action = WordPressSiteAction.fetchApplicationPasswordAuthorizationURL(siteURL: self.sampleSiteURL) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let url = try result.get()
        XCTAssertEqual(url?.absoluteString, "https://example.com/wp-admin/authorize-application.php")
    }

    func test_fetchApplicationPasswordAuthorizationURL_relays_error_properly() throws {
        // Given
        network.simulateError(requestUrlSuffix: "?rest_route=/", error: NetworkError.notFound())
        let store = WordPressSiteStore(network: network, dispatcher: dispatcher)

        // When
        let result: Result<URL?, Error> = waitFor { promise in
            let action = WordPressSiteAction.fetchApplicationPasswordAuthorizationURL(siteURL: self.sampleSiteURL) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertTrue(result.failure is NetworkError)
    }

    func test_fetchPageList_returns_correct_page_list() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "/?rest_route=/wp/v2/pages&_fields=id,title,link", filename: "wp-page-list-success")
        let store = WordPressSiteStore(network: network, dispatcher: dispatcher)

        // When
        let result: Result<[WordPressPage], Error> = waitFor { promise in
            let action = WordPressSiteAction.fetchPageList(siteURL: self.sampleSiteURL) { result in
                promise(result)
            }
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

    func test_fetchPageList_relays_error_properly() throws {
        // Given
        network.simulateError(requestUrlSuffix: "/?rest_route=/wp/v2/pages&_fields=id,title,link", error: NetworkError.notFound())
        let store = WordPressSiteStore(network: network, dispatcher: dispatcher)

        // When
        let result: Result<[WordPressPage], Error> = waitFor { promise in
            let action = WordPressSiteAction.fetchPageList(siteURL: self.sampleSiteURL) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertTrue(result.failure is NetworkError)
    }
}
