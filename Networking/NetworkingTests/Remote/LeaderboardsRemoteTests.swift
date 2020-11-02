import XCTest
@testable import Networking

/// Leaderboards Unit Tests
///
final class LeaderboardsRemoteV4Tests: XCTestCase {

    let network = MockupNetwork()
    let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    func testLeaderboardReturnsCorrectParsedValues() throws {
        // Given
        let remote = LeaderboardsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "leaderboards", filename: "leaderboards-year")

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
        let expectedValues = [(quantity: 4, total: 20000.0), (quantity: 1, total: 15.99)]
        zip(topProducts.rows, expectedValues).forEach { product, expectedValue in
            XCTAssertFalse(product.subject.display.isEmpty)
            XCTAssertFalse(product.subject.value.isEmpty)
            XCTAssertFalse(product.quantity.display.isEmpty)
            XCTAssertEqual(product.quantity.value, expectedValue.quantity)
            XCTAssertFalse(product.total.display.isEmpty)
            XCTAssertEqual(product.total.value, expectedValue.total)
        }
    }

    func testLeaderboardsProperlyRelaysNetwokingErrors() {
        // Given
        let remote = LeaderboardsRemote(network: network)

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
        XCTAssertNotNil(remoteResult?.failure)
    }
}
