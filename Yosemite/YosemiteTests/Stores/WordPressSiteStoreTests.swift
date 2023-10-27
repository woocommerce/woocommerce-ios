import XCTest
@testable import Yosemite
@testable import Networking

final class WordPressSiteStoreTests: XCTestCase {

    private var remote: MockWordPressSiteRemote!

    /// Mock Dispatcher
    ///
    private var dispatcher: Dispatcher!

    private let sampleSiteURL = "https://test.com"

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        remote = MockWordPressSiteRemote()
    }

    func test_fetchSiteInfo_returns_correct_site() throws {
        // Given
        let store = WordPressSiteStore(remote: remote, dispatcher: dispatcher)

        // When
        remote.mockSiteInfo(mockedSite())
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
        let store = WordPressSiteStore(remote: remote, dispatcher: dispatcher)

        // When
        remote.mockFailure(error: NetworkError.notFound)
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
        let store = WordPressSiteStore(remote: remote, dispatcher: dispatcher)

        // When
        remote.mockSiteInfo(mockedSite(applicationPasswordAuthorizationURL: nil))
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
        let store = WordPressSiteStore(remote: remote, dispatcher: dispatcher)

        // When
        remote.mockSiteInfo(mockedSite(applicationPasswordAuthorizationURL: "https://example.com/wp-admin/authorize-application.php"))
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
        let store = WordPressSiteStore(remote: remote, dispatcher: dispatcher)

        // When
        remote.mockFailure(error: NetworkError.timeout)
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
}

private extension WordPressSiteStoreTests {
    func mockedSite(applicationPasswordAuthorizationURL: String? = nil) -> WordPressSite {
        .init(name: "My WordPress Site",
              description: "Just another WordPress site",
              url: "https://test.com",
              timezone: "",
              gmtOffset: "0",
              namespaces: [],
              applicationPasswordAuthorizationURL: applicationPasswordAuthorizationURL)
    }
}
