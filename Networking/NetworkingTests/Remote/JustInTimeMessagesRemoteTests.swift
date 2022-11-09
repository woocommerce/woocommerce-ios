import XCTest
@testable import Networking
import TestKit

final class JustInTimeMessagesRemoteTests: XCTestCase {
    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    // MARK: - Load all Just In Time Messages tests

    /// Verifies that loadAllJustInTimeMessages properly parses the `just-in-time-message-list` sample response.
    ///
    func test_loadAllJustInTimeMessages_returns_parsed_messages() async throws {
        // Given
        let remote = JustInTimeMessagesRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "jetpack/v4/jitm", filename: "just-in-time-message-list")

        // When
        let result = await remote.loadAllJustInTimeMessages(
                for: self.sampleSiteID,
                messagePath: JustInTimeMessagesRemote.MessagePath(
                    app: .wooMobile,
                    screen: "my_store",
                    hook: .adminNotices),
                query: nil,
                locale: "en_US")

        // Then
        XCTAssert(result.isSuccess)
        let justInTimeMessages = try XCTUnwrap(result.get())
        assertEqual(1, justInTimeMessages.count)
    }

    /// Verifies that loadAllJustInTimeMessages uses the SiteID passed in for the request.
    ///
    func test_loadAllJustInTimeMessages_uses_passed_siteID_for_request() async throws {
        // Given
        let remote = JustInTimeMessagesRemote(network: network)

        // When
        _ = await remote.loadAllJustInTimeMessages(
            for: self.sampleSiteID,
            messagePath: JustInTimeMessagesRemote.MessagePath(
                app: .wooMobile,
                screen: "my_store",
                hook: .adminNotices),
            query: nil,
            locale: "en_US")

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? JetpackRequest)
        XCTAssertEqual(request.siteID, sampleSiteID)
    }

    /// Verifies that loadAllJustInTimeMessages uses the SiteID passed in to build the models.
    ///
    func test_loadAllJustInTimeMessages_uses_passed_siteID_for_model_creation() async throws {
        // Given
        let remote = JustInTimeMessagesRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "jetpack/v4/jitm", filename: "just-in-time-message-list")

        // When
        let result = await remote.loadAllJustInTimeMessages(
                for: self.sampleSiteID,
                messagePath: JustInTimeMessagesRemote.MessagePath(
                    app: .wooMobile,
                    screen: "my_store",
                    hook: .adminNotices),
                query: nil,
                locale: "en_US")

        // Then
        let justInTimeMessages = try result.get()
        assertEqual(sampleSiteID, justInTimeMessages.first?.siteID)
    }

    /// Verifies that loadAllJustInTimeMessages uses the messagePath passed in for the request.
    ///
    func test_loadAllJustInTimeMessages_uses_passed_messagePath_for_request() async throws {
        // Given
        let remote = JustInTimeMessagesRemote(network: network)

        // When
        _ = await remote.loadAllJustInTimeMessages(
            for: self.sampleSiteID,
            messagePath: JustInTimeMessagesRemote.MessagePath(
                app: .wooMobile,
                screen: "my_store",
                hook: .adminNotices),
            query: nil,
            locale: "en_US")

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? JetpackRequest)
        let url = try XCTUnwrap(request.urlRequest?.url)
        let queryItems = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        let queryJson = try XCTUnwrap(queryItems.first { $0.name == "query" }?.value)
        assertThat(queryJson, contains: "woomobile:my_store:admin_notices")
    }

    /// Verifies that loadAllJustInTimeMessages properly relays Networking Layer errors.
    ///
    func test_loadAllJustInTimeMessages_properly_relays_networking_errors() async throws {
        // Given
        let remote = JustInTimeMessagesRemote(network: network)

        let error = NetworkError.unacceptableStatusCode(statusCode: 403)
        network.simulateError(requestUrlSuffix: "jetpack/v4/jitm", error: error)

        // When
        let result = await remote.loadAllJustInTimeMessages(
                for: self.sampleSiteID,
                messagePath: JustInTimeMessagesRemote.MessagePath(
                    app: .wooMobile,
                    screen: "my_store",
                    hook: .adminNotices),
                query: nil,
                locale: "en_US")

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        assertEqual(error, resultError)
    }

    func test_test_loadAllJustInTimeMessages_uses_passed_locale_for_request() async throws {
        // Given
        let remote = JustInTimeMessagesRemote(network: network)

        // When
        _ = await remote.loadAllJustInTimeMessages(
            for: self.sampleSiteID,
            messagePath: JustInTimeMessagesRemote.MessagePath(
                app: .wooMobile,
                screen: "my_store",
                hook: .adminNotices),
            query: nil,
            locale: "en_US")

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? JetpackRequest)
        let url = try XCTUnwrap(request.urlRequest?.url)
        let queryItems = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        let locale = try XCTUnwrap(queryItems.first { $0.name == "locale" }?.value)
        assertEqual("en_US", locale)
    }

    func test_test_loadAllJustInTimeMessages_uses_passed_query_for_request() async throws {
        // Given
        let remote = JustInTimeMessagesRemote(network: network)

        // When
        _ = await remote.loadAllJustInTimeMessages(
            for: self.sampleSiteID,
            messagePath: JustInTimeMessagesRemote.MessagePath(
                app: .wooMobile,
                screen: "my_store",
                hook: .adminNotices),
            query: [
                "platform": "ios",
                "version": "11.1"
            ],
            locale: "en_US")

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? JetpackRequest)
        let url = try XCTUnwrap(request.urlRequest?.url)
        let queryItems = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        let queryJson = try XCTUnwrap(queryItems.first { $0.name == "query" }?.value)
        assertThat(queryJson, contains: "\"query\":")
        let parameters = request.parameters
        let jitmQuery = try XCTUnwrap(request.parameters["query"] as? String)
        // Individually check query items because dictionaries aren't ordered
        assertThat(jitmQuery, contains: "platform=ios") // platform=ios
        assertThat(jitmQuery, contains: "version=11.1") // version=11.1
    }
}
