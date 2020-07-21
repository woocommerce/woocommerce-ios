import XCTest
@testable import Networking

/// Leaderboards Unit Tests
///
final class leaderboardsRemoteV4Tests: XCTestCase {

    let network = MockupNetwork()
    let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    func testLeaderboardReturnsCorrectParsedValues() throws {

        // Given
        let remote = LeaderboardsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "wc-analytics/leaderboards", filename: "leaderboards-year")

        // When
        var remoteResult: Result<[Leaderboard], Error>?
        waitForExpectation { exp in
            remote.loadLeaderboards(for: sampleSiteID,
                                    unit: .yearly,
                                    earliestDateToInclude: "2020-01-01T00:00:00",
                                    latestDateToInclude: "2020-12-31T23:59:59",
                                    quantity: 3) { result in
                                        remoteResult = result
                                        exp.fulfill()
            }
        }

        // Then
        let leaderboards = try XCTUnwrap(remoteResult?.get())

        // API Returns 4 leaderboards
        XCTAssertEqual(leaderboards.count, 4)

        // The 4th leaderboard contains the top products and should not be empty
        let topProducts = leaderboards[3]
        XCTAssertFalse(topProducts.rows.isEmpty)

        // Each prodcut should have non-empty values
        topProducts.rows.forEach { product in
            XCTAssertFalse(product.subject.display.isEmpty)
            XCTAssertFalse(product.subject.value.isEmpty)
            XCTAssertFalse(product.subjectValue.display.isEmpty)
            XCTAssertTrue(product.subjectValue.value > 0)
            XCTAssertFalse(product.value.display.isEmpty)
            XCTAssertTrue(product.value.value > 0)
        }
    }
}
