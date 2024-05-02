import XCTest
import TestKit
@testable import Networking


/// GiftCardStatsRemote Unit Tests
///
class GiftCardStatsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }


    /// Verifies that loadUsedGiftCardStats properly parses the `GiftCardStats` sample response.
    ///
    func test_loadUsedGiftCardStats_properly_returns_parsed_stats() async throws {
        // Given
        let remote = GiftCardStatsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/giftcards/used/stats", filename: "gift-card-stats")

        // When
        let giftCardStats = try await remote.loadUsedGiftCardStats(for: self.sampleSiteID,
                                                                   unit: .daily,
                                                                   timeZone: .gmt,
                                                                   earliestDateToInclude: Date(),
                                                                   latestDateToInclude: Date(),
                                                                   quantity: 2,
                                                                   forceRefresh: false)

        // Then
        XCTAssertEqual(giftCardStats.intervals.count, 1)
    }

    /// Verifies that loadUsedGiftCardStats properly relays Networking Layer errors.
    ///
    func test_loadUsedGiftCardStats_properly_relays_networking_errors() async {
        // Given
        let remote = GiftCardStatsRemote(network: network)
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        network.simulateError(requestUrlSuffix: "reports/giftcards/used/stats", error: expectedError)

        // When & Then
        await assertThrowsError({
            _ = try await remote.loadUsedGiftCardStats(for: self.sampleSiteID,
                                                       unit: .daily,
                                                       timeZone: .gmt,
                                                       earliestDateToInclude: Date(),
                                                       latestDateToInclude: Date(),
                                                       quantity: 2,
                                                       forceRefresh: false)
        }, errorAssert: { ($0 as? NetworkError) == expectedError })
    }
}
