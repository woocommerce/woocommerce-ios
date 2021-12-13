import XCTest
@testable import Networking

/// OrderStatsRemote Unit Tests
///
final class OrderStatsRemoteV4Tests: XCTestCase {

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

    /// Verifies that loadOrderStats properly parses the `OrderStatsV4` sample response
    /// when requesting the hourly stats
    ///
    func test_loadOrderStats_properly_returns_parsed_stats_for_hourly_stats() throws {
        // Given
        let remote = OrderStatsRemoteV4(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/revenue/stats", filename: "order-stats-v4-hour")

        // When
        let result: Result<OrderStatsV4, Error> = waitFor { promise in
            remote.loadOrderStats(for: self.sampleSiteID,
                                  unit: .hourly,
                                  earliestDateToInclude: Date(),
                                  latestDateToInclude: Date(),
                                  quantity: 24) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let orderStatsV4 = try result.get()
        XCTAssertEqual(orderStatsV4.intervals.count, 24)
    }

    /// Verifies that loadOrderStats properly parses the `OrderStatsV4` sample response
    /// when requesting the weekly stats
    ///
    func test_loadOrderStats_properly_returns_parsed_stats_for_weekly_stats() throws {
        // Given
        let remote = OrderStatsRemoteV4(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/revenue/stats", filename: "order-stats-v4-defaults")

        // When
        let result: Result<OrderStatsV4, Error> = waitFor { promise in
            remote.loadOrderStats(for: self.sampleSiteID,
                                  unit: .weekly,
                                  earliestDateToInclude: Date(),
                                  latestDateToInclude: Date(),
                                  quantity: 2) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let orderStatsV4 = try result.get()
        XCTAssertEqual(orderStatsV4.intervals.count, 2)
    }

    /// Verifies that loadOrderStats properly relays Networking Layer errors.
    ///
    func test_loadOrderStats_properly_relays_netwoking_errors() {
        // Given
        let remote = OrderStatsRemoteV4(network: network)

        // When
        let result: Result<OrderStatsV4, Error> = waitFor { promise in
            remote.loadOrderStats(for: self.sampleSiteID,
                                  unit: .daily,
                                  earliestDateToInclude: Date(),
                                  latestDateToInclude: Date(),
                                  quantity: 31) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}
