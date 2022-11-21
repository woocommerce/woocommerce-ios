import XCTest
import TestKit
@testable import Networking

final class DomainRemoteTests: XCTestCase {
    /// Mock network wrapper.
    private var network: MockNetwork!

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    func test_loadFreeDomainSuggestions_returns_suggestions_on_success() async throws {
        // Given
        let remote = DomainRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "domains/suggestions", filename: "domain-suggestions")

        // When
        let suggestions = try await remote.loadFreeDomainSuggestions(query: "domain")

        // Then
        XCTAssertEqual(suggestions, [
            .init(name: "domaintestingtips.wordpress.com", isFree: true),
            .init(name: "domaintestingtoday.wordpress.com", isFree: true),
        ])
    }

    func test_loadFreeDomainSuggestions_returns_error_on_empty_response() async throws {
        // Given
        let remote = DomainRemote(network: network)

        await assertThrowsError({_ = try await remote.loadFreeDomainSuggestions(query: "domain")}, errorAssert: { ($0 as? NetworkError) == .notFound })
    }
}
