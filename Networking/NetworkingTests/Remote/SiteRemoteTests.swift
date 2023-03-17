import XCTest
import TestKit
@testable import Networking

final class SiteRemoteTests: XCTestCase {
    /// Mock network wrapper.
    private var network: MockNetwork!

    private var remote: SiteRemote!

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        remote = SiteRemote(network: network, dotcomClientID: "", dotcomClientSecret: "")
    }

    override func tearDown() {
        remote = nil
        network = nil
        super.tearDown()
    }

    // MARK: - `createSite`

    func test_createSite_returns_created_site_on_success() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "sites/new", filename: "site-creation-success")

        // When
        let response = try await remote.createSite(name: "Wapuu swags", domain: "wapuu.store")

        // Then
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.site, .init(siteID: "202211",
                                            name: "Wapuu swags",
                                            url: "https://wapuu.store/",
                                            siteSlug: "wapuu.store"))
    }

    func test_createSite_returns_invalidDomain_error_when_domain_is_empty() async throws {
        await assertThrowsError({ _ = try await remote.createSite(name: "Wapuu swags", domain: "") },
                                errorAssert: { ($0 as? SiteCreationError) == .invalidDomain} )
    }

    func test_createSite_returns_DotcomError_failure_on_domain_error() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "sites/new", filename: "site-creation-domain-error")

        await assertThrowsError({
            // When
            _ = try await remote.createSite(name: "Wapuu swags", domain: "wapuu.store")
        }, errorAssert: { ($0 as? DotcomError) == .unknown(code: "blog_name_only_lowercase_letters_and_numbers",
                                                message: "Site names can only contain lowercase letters (a-z) and numbers.")
        })
    }

    func test_createSite_returns_failure_on_empty_response() async throws {
        await assertThrowsError({
            // When
            _ = try await remote.createSite(name: "Wapuu swags", domain: "wapuu.store")
        }, errorAssert: { ($0 as? NetworkError) == .notFound })
    }

    // MARK: - `launchSite`

    func test_launchSite_returns_on_success() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "launch", filename: "site-launch-success")

        // When
        do {
            try await remote.launchSite(siteID: 134)
        } catch {
            // Then
            XCTFail("Unexpected failure launching site: \(error)")
        }
    }

    func test_launchSite_returns_DotcomError_failure_on_already_launched_error() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "launch", filename: "site-launch-error-already-launched")

        await assertThrowsError({
            // When
            try await remote.launchSite(siteID: 134)
        }, errorAssert: {
            ($0 as? WordPressApiError) == .unknown(code: "already-launched",
                                                   message: "This site has already been launched")
        })
    }

    func test_launchSite_returns_WordPressApiError_failure_on_unauthorized_error() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "launch", filename: "site-launch-error-unauthorized")

        await assertThrowsError({
            // When
            try await remote.launchSite(siteID: 134)
        }, errorAssert: {
            ($0 as? WordPressApiError) == .unknown(code: "unauthorized",
                                                   message: "You do not have permission to launch this site.")
        })
    }

    func test_launchSite_returns_failure_on_empty_response() async throws {
        await assertThrowsError({
            // When
            _ = try await remote.launchSite(siteID: 134)
        }, errorAssert: { ($0 as? NetworkError) == .notFound })
    }
}
