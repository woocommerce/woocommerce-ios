import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage

/// StatsStoreV4Tests Unit Tests
///
final class StatsStoreV4Tests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 123


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: - StatsActionV4.retrieveStats

    /// Verifies that `StatsActionV4.retrieveStats` effectively persists any retrieved OrderStatsV4.
    ///
    func test_retrieveStats_effectively_persists_retrieved_stats() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "reports/revenue/stats", filename: "order-stats-v4-year")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatsV4.self), 0)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveStats(siteID: self.sampleSiteID,
                                                     timeRange: .thisYear,
                                                     earliestDateToInclude: DateFormatter.dateFromString(with: "2018-06-23T17:06:55"),
                                                     latestDateToInclude: DateFormatter.dateFromString(with: "2018-06-23T17:06:55"),
                                                     quantity: 2,
                                                     forceRefresh: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatsV4.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatsV4Interval.self), 1)
        let readOnlyOrderStats = viewStorage.firstObject(ofType: Storage.OrderStatsV4.self)?.toReadOnly()
        assertEqual(sampleStats(), readOnlyOrderStats)
    }

    /// Verifies that `StatsActionV4.retrieveStats` returns an error whenever there is an error response from the backend.
    ///
    func test_retrieveStats_returns_error_upon_reponse_error() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "reports/revenue/stats", filename: "generic_error")

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveStats(siteID: self.sampleSiteID,
                                                     timeRange: .thisYear,
                                                     earliestDateToInclude: DateFormatter.dateFromString(with: "2018-06-23T17:06:55"),
                                                     latestDateToInclude: DateFormatter.dateFromString(with: "2018-06-23T17:06:55"),
                                                     quantity: 2,
                                                     forceRefresh: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `StatsActionV4.retrieveStats` returns an error whenever there is no backend response.
    ///
    func test_retrieveStats_returns_error_upon_empty_response() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveStats(siteID: self.sampleSiteID,
                                                     timeRange: .thisYear,
                                                     earliestDateToInclude: DateFormatter.dateFromString(with: "2018-06-23T17:06:55"),
                                                     latestDateToInclude: DateFormatter.dateFromString(with: "2018-06-23T17:06:55"),
                                                     quantity: 2,
                                                     forceRefresh: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - StatsActionV4.retrieveSiteVisitStats


    /// Verifies that `StatsActionV4.retrieveSiteVisitStats` effectively persists any retrieved SiteVisitStats.
    ///
    func test_retrieveSiteVisitStats_effectively_persists_retrieved_stats() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/visits/", filename: "site-visits")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 0)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveSiteVisitStats(siteID: self.sampleSiteID,
                                                              siteTimezone: .current,
                                                              timeRange: .thisWeek,
                                                              latestDateToInclude: DateFormatter.dateFromString(with: "2018-08-06T17:06:55")) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStatsItem.self), 2)
        let readOnlySiteVisitStats = viewStorage.firstObject(ofType: Storage.SiteVisitStats.self)?.toReadOnly()
        XCTAssertEqual(readOnlySiteVisitStats, sampleSiteVisitStats())
    }

    /// Verifies that `StatsActionV4.retrieveSiteVisitStats` effectively persists any updated SiteVisitStatsItems.
    ///
    func test_retrieveSiteVisitStats_effectively_persists_updated_items() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 0)
        store.upsertStoredSiteVisitStats(readOnlyStats: sampleSiteVisitStats(), timeRange: .thisYear)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStatsItem.self), 2)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/visits/", filename: "site-visits-alt")

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveSiteVisitStats(siteID: self.sampleSiteID,
                                                              siteTimezone: .current,
                                                              timeRange: .thisYear,
                                                              latestDateToInclude: DateFormatter.dateFromString(with: "2018-08-06T17:06:55")) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStatsItem.self), 2)
        let readOnlySiteVisitStats = viewStorage.firstObject(ofType: Storage.SiteVisitStats.self)?.toReadOnly()
        XCTAssertEqual(readOnlySiteVisitStats, sampleSiteVisitStatsMutated())
    }

    /// Verifies that `StatsActionV4.retrieveSiteVisitStats` returns an error whenever there is an error response from the backend.
    ///
    func test_retrieveSiteVisitStats_returns_error_upon_reponse_error() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/visits/", filename: "generic_error")

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveSiteVisitStats(siteID: self.sampleSiteID,
                                                              siteTimezone: .current,
                                                              timeRange: .thisYear,
                                                              latestDateToInclude: DateFormatter.dateFromString(with: "2018-08-06T17:06:55")) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `StatsActionV4.retrieveSiteVisitStats` returns an error whenever there is no backend response.
    ///
    func test_retrieveSiteVisitStats_returns_error_upon_empty_response() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveSiteVisitStats(siteID: self.sampleSiteID,
                                                              siteTimezone: .current,
                                                              timeRange: .thisYear,
                                                              latestDateToInclude: DateFormatter.dateFromString(with: "2018-08-06T17:06:55")) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `upsertStoredSiteVisitStats` effectively inserts a new SiteVisitStats, with the specified payload.
    ///
    func test_upsertStoredSiteVisitStats_effectively_persists_new_SiteVisitStats() {
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteSiteVisitStats = sampleSiteVisitStats()
        let timeRange = StatsTimeRangeV4.thisYear

        XCTAssertNil(viewStorage.loadSiteVisitStats(granularity: StatGranularity.year.rawValue, timeRange: timeRange.rawValue))
        statsStore.upsertStoredSiteVisitStats(readOnlyStats: remoteSiteVisitStats, timeRange: timeRange)

        let storageSiteVisitStats = viewStorage.loadSiteVisitStats(granularity: StatGranularity.year.rawValue, timeRange: timeRange.rawValue)
        XCTAssertEqual(storageSiteVisitStats?.toReadOnly(), remoteSiteVisitStats)
    }

    /// Verifies that `upsertStoredSiteVisitStats` does not produce duplicate entries.
    ///
    func test_upsertStoredSiteVisitStats_effectively_updates_preexistant_SiteVisitStats() {
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let timeRange = StatsTimeRangeV4.thisYear

        XCTAssertNil(viewStorage.loadSiteVisitStats(granularity: StatGranularity.year.rawValue, timeRange: timeRange.rawValue))
        statsStore.upsertStoredSiteVisitStats(readOnlyStats: sampleSiteVisitStats(), timeRange: timeRange)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStatsItem.self), 2)
        statsStore.upsertStoredSiteVisitStats(readOnlyStats: sampleSiteVisitStatsMutated(), timeRange: timeRange)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStats.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteVisitStatsItem.self), 2)

        let expectedSiteVisitStats = sampleSiteVisitStatsMutated()
        let storageSiteVisitStats = viewStorage.loadSiteVisitStats(granularity: StatGranularity.year.rawValue, timeRange: timeRange.rawValue)
        XCTAssertEqual(storageSiteVisitStats?.toReadOnly(), expectedSiteVisitStats)
    }

    // MARK: - StatsActionV4.retrieveTopEarnerStats


    /// Verifies that `StatsActionV4.retrieveTopEarnerStats` effectively persists any retrieved TopEarnerStats.
    ///
    func test_retrieveTopEarnerStats_effectively_persists_retrieved_stats() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "leaderboards/products", filename: "leaderboards-year")
        network.simulateResponse(requestUrlSuffix: "products", filename: "leaderboards-products")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStats.self), 0)

        // When
        let result: Result<Networking.TopEarnerStats, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveTopEarnerStats(siteID: self.sampleSiteID,
                                                              timeRange: .thisYear,
                                                              earliestDateToInclude: DateFormatter.dateFromString(with: "2020-01-01T00:00:00"),
                                                              latestDateToInclude: DateFormatter.dateFromString(with: "2020-07-22T12:00:00"),
                                                              quantity: 3,
                                                              forceRefresh: false,
                                                              saveInStorage: true) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStats.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStatsItem.self), 2)

        let readOnlyTopEarnerStats = viewStorage.firstObject(ofType: Storage.TopEarnerStats.self)?.toReadOnly()
        XCTAssertEqual(readOnlyTopEarnerStats, sampleTopEarnerStats())
    }

    /// Verifies that `StatsActionV4.retrieveTopEarnerStats` makes a network request with the given quantity parameter.
    ///
    func test_retrieveTopEarnerStats_makes_network_request_with_given_quantity_parameter() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let quantity = 6
        let _: Void = waitFor { promise in
            let action = StatsActionV4.retrieveTopEarnerStats(siteID: self.sampleSiteID,
                                                              timeRange: .thisYear,
                                                              earliestDateToInclude: DateFormatter.dateFromString(with: "2020-01-01T00:00:00"),
                                                              latestDateToInclude: DateFormatter.dateFromString(with: "2020-07-22T12:00:00"),
                                                              quantity: quantity,
                                                              forceRefresh: false,
                                                              saveInStorage: true) { result in
                promise(())
            }
            store.onAction(action)
        }

        // Then
        let expectedQuantityParam = "per_page=\(quantity)"
        XCTAssertEqual(network.queryParameters?.contains(expectedQuantityParam), true)
    }

    /// Verifies that `StatsActionV4.retrieveTopEarnerStats` makes a network request with the given `force_cache_refresh` parameter.
    ///
    func test_retrieveTopEarnerStats_makes_network_request_with_given_force_cache_rerefresh_parameter() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let _: Void = waitFor { promise in
            let action = StatsActionV4.retrieveTopEarnerStats(siteID: self.sampleSiteID,
                                                              timeRange: .thisYear,
                                                              earliestDateToInclude: DateFormatter.dateFromString(with: "2020-01-01T00:00:00"),
                                                              latestDateToInclude: DateFormatter.dateFromString(with: "2020-07-22T12:00:00"),
                                                              quantity: 1,
                                                              forceRefresh: true,
                                                              saveInStorage: true) { result in
                promise(())
            }
            store.onAction(action)
        }

        // Then
        let expectedParam = "force_cache_refresh=1"
        XCTAssertEqual(network.queryParameters?.contains(expectedParam), true)
    }

    /// Verifies that `StatsActionV4.retrieveStats` makes a network request with the given `force_cache_refresh` parameter.
    ///
    func test_retrieveStats_makes_network_request_with_given_force_cache_rerefresh_parameter() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let _: Void = waitFor { promise in
            let action = StatsActionV4.retrieveStats(siteID: self.sampleSiteID,
                                                     timeRange: .thisMonth,
                                                     earliestDateToInclude: .init(),
                                                     latestDateToInclude: .init(),
                                                     quantity: 1,
                                                     forceRefresh: false) { _ in
                promise(())
            }
            store.onAction(action)
        }

        // Then
        let expectedParam = "force_cache_refresh=0"
        XCTAssertEqual(network.queryParameters?.contains(expectedParam), true)
    }

    /// Verifies that `StatsActionV4.retrieveTopEarnerStats` effectively persists any updated TopEarnerStatsItems.
    ///
    func test_retrieveTopEarnerStats_effectively_persists_updated_items() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "leaderboards/products", filename: "leaderboards-year-alt")
        network.simulateResponse(requestUrlSuffix: "products", filename: "leaderboards-products")
        store.upsertStoredTopEarnerStats(readOnlyStats: sampleTopEarnerStats())

        // When
        let result: Result<Networking.TopEarnerStats, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveTopEarnerStats(siteID: self.sampleSiteID,
                                                              timeRange: .thisYear,
                                                              earliestDateToInclude: DateFormatter.dateFromString(with: "2020-01-01T00:00:00"),
                                                              latestDateToInclude: DateFormatter.dateFromString(with: "2020-07-22T12:00:00"),
                                                              quantity: 3,
                                                              forceRefresh: false,
                                                              saveInStorage: true) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStats.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStatsItem.self), 2)

        let readOnlyTopEarnerStats = viewStorage.firstObject(ofType: Storage.TopEarnerStats.self)?.toReadOnly()
        XCTAssertEqual(readOnlyTopEarnerStats, sampleTopEarnerStatsMutated())
    }

    func test_retrieveTopEarnerStats_calls_deprecated_leaderboards_api_and_persits_stats_on_leaderboards_restnoroute_error() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateError(requestUrlSuffix: "leaderboards/products", error: DotcomError.noRestRoute)
        network.simulateResponse(requestUrlSuffix: "leaderboards", filename: "leaderboards-year")
        network.simulateResponse(requestUrlSuffix: "products", filename: "leaderboards-products")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStats.self), 0)

        // When
        let result: Result<Networking.TopEarnerStats, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveTopEarnerStats(siteID: self.sampleSiteID,
                                                              timeRange: .thisYear,
                                                              earliestDateToInclude: DateFormatter.dateFromString(with: "2020-01-01T00:00:00"),
                                                              latestDateToInclude: DateFormatter.dateFromString(with: "2020-07-22T12:00:00"),
                                                              quantity: 3,
                                                              forceRefresh: false,
                                                              saveInStorage: true) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStats.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStatsItem.self), 2)

        let readOnlyTopEarnerStats = viewStorage.firstObject(ofType: Storage.TopEarnerStats.self)?.toReadOnly()
        XCTAssertEqual(readOnlyTopEarnerStats, sampleTopEarnerStats())
    }

    /// Verifies that `StatsActionV4.retrieveTopEarnerStats` returns an error whenever there is an error response from the backend.
    ///
    func test_retrieveTopEarnerStats_returns_error_upon_response_error() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/top-earners/", filename: "generic_error")

        // When
        let result: Result<Networking.TopEarnerStats, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveTopEarnerStats(siteID: self.sampleSiteID,
                                                              timeRange: .thisMonth,
                                                              earliestDateToInclude: Date(),
                                                              latestDateToInclude: Date(),
                                                              quantity: 3,
                                                              forceRefresh: false,
                                                              saveInStorage: true) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `StatsActionV4.retrieveTopEarnerStats` returns an error whenever there is no backend response.
    ///
    func test_retrieveTopEarnerStats_returns_error_upon_empty_response() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Networking.TopEarnerStats, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveTopEarnerStats(siteID: self.sampleSiteID,
                                                              timeRange: .thisMonth,
                                                              earliestDateToInclude: Date(),
                                                              latestDateToInclude: Date(),
                                                              quantity: 3,
                                                              forceRefresh: false,
                                                              saveInStorage: true) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `upsertStoredTopEarnerStats` effectively inserts a new TopEarnerStats, with the specified payload.
    ///
    func test_upsertStoredTopEarnerStats_effectively_persists_new_TopEarnersStats() {
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteTopEarnersStats = sampleTopEarnerStats()

        XCTAssertNil(viewStorage.loadTopEarnerStats(date: "2020", granularity: StatGranularity.year.rawValue))
        statsStore.upsertStoredTopEarnerStats(readOnlyStats: remoteTopEarnersStats)

        let storageTopEarnersStats = viewStorage.loadTopEarnerStats(date: "2020", granularity: StatGranularity.year.rawValue)
        XCTAssertEqual(storageTopEarnersStats?.toReadOnly(), remoteTopEarnersStats)
    }

    /// Verifies that `upsertStoredTopEarnerStats` does not produce duplicate entries.
    ///
    func test_upsertStoredTopEarnerStats_effectively_updates_preexistant_TopEarnersStats() {
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertNil(viewStorage.loadTopEarnerStats(date: "2020", granularity: StatGranularity.week.rawValue))
        statsStore.upsertStoredTopEarnerStats(readOnlyStats: sampleTopEarnerStats())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStats.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStatsItem.self), 2)
        statsStore.upsertStoredTopEarnerStats(readOnlyStats: sampleTopEarnerStatsMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStats.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TopEarnerStatsItem.self), 2)

        let expectedTopEarnerStats = sampleTopEarnerStatsMutated()
        let storageTopEarnerStats = viewStorage.loadTopEarnerStats(date: "2020", granularity: StatGranularity.year.rawValue)
        XCTAssertEqual(storageTopEarnerStats?.toReadOnly(), expectedTopEarnerStats)
    }

    // MARK: - StatsStoreV4.retrieveSiteSummaryStats

    /// Verifies that `StatsActionV4.retrieveSiteSummaryStats` returns any retrieved SiteSummaryStats.
    ///
    func test_retrieveSiteSummaryStats_returns_retrieved_stats() throws {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/summary/", filename: "site-summary-stats")

        // When
        let result: Result<Networking.SiteSummaryStats, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveSiteSummaryStats(siteID: self.sampleSiteID,
                                                                siteTimezone: .current,
                                                                period: .day,
                                                                quantity: 1,
                                                                latestDateToInclude: DateFormatter.dateFromString(with: "2022-12-09T17:06:55"),
                                                                saveInStorage: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let siteSummaryStats = try XCTUnwrap(result).get()
        XCTAssertEqual(siteSummaryStats, sampleSiteSummaryStats())
    }

    /// Verifies that `StatsActionV4.retrieveSiteSummaryStats` makes the expected alternate network request for multiple stats periods.
    ///
    func test_retrieveSiteSummaryStats_makes_expected_network_request_for_multiple_periods() throws {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let _: Void = waitFor { promise in
            let action = StatsActionV4.retrieveSiteSummaryStats(siteID: self.sampleSiteID,
                                                                siteTimezone: .init(identifier: "GMT") ?? .current,
                                                                period: .month,
                                                                quantity: 3,
                                                                latestDateToInclude: DateFormatter.dateFromString(with: "2022-12-31T17:06:55"),
                                                                saveInStorage: false) { _ in
                promise(())
            }
            store.onAction(action)
        }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? DotcomRequest)
        XCTAssertEqual(request.path, "sites/\(sampleSiteID)/stats/visits/")
        XCTAssertEqual(request.parameters?["date"] as? String, "2022-12-31")
        XCTAssertEqual(request.parameters?["unit"] as? String, "month")
        XCTAssertEqual(request.parameters?["quantity"] as? String, "3")
    }

    /// Verifies that `StatsActionV4.retrieveSiteSummaryStats` converts and returns SiteSummaryStats for multiple periods.
    ///
    func test_retrieveSiteSummaryStats_returns_retrieved_quarter_stats() throws {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/visits/", filename: "site-visits-quarter")

        // When
        let result: Result<Networking.SiteSummaryStats, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveSiteSummaryStats(siteID: self.sampleSiteID,
                                                                siteTimezone: .current,
                                                                period: .month,
                                                                quantity: 3,
                                                                latestDateToInclude: DateFormatter.dateFromString(with: "2022-12-31T17:06:55"),
                                                                saveInStorage: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let siteSummaryStats = try XCTUnwrap(result).get()
        XCTAssertEqual(siteSummaryStats, sampleSiteSummaryStatsQuarter())
    }

    /// Verifies that `StatsActionV4.retrieveSiteSummaryStats` returns an error whenever there is an error response from the backend.
    ///
    func test_retrieveSiteSummaryStats_returns_error_upon_response_error() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/summary/", filename: "generic_error")

        // When
        let result: Result<Networking.SiteSummaryStats, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveSiteSummaryStats(siteID: self.sampleSiteID,
                                                                siteTimezone: .current,
                                                                period: .day,
                                                                quantity: 1,
                                                                latestDateToInclude: DateFormatter.dateFromString(with: "2022-12-09T17:06:55"),
                                                                saveInStorage: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `StatsActionV4.retrieveSiteSummaryStats` returns an error whenever there is no backend response.
    ///
    func test_retrieveSiteSummaryStats_returns_error_upon_empty_response() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Networking.SiteSummaryStats, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveSiteSummaryStats(siteID: self.sampleSiteID,
                                                                siteTimezone: .current,
                                                                period: .day,
                                                                quantity: 1,
                                                                latestDateToInclude: DateFormatter.dateFromString(with: "2022-12-09T17:06:55"),
                                                                saveInStorage: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `StatsActionV4.retrieveSiteSummaryStats` effectively persists any retrieved SiteSummaryStats.
    ///
    func test_retrieveSiteSummaryStats_effectively_persists_retrieved_stats() {
        // Given
        let store = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/summary/", filename: "site-summary-stats")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSummaryStats.self), 0)

        // When
        let result: Result<Networking.SiteSummaryStats, Error> = waitFor { promise in
            let action = StatsActionV4.retrieveSiteSummaryStats(siteID: self.sampleSiteID,
                                                                siteTimezone: .current,
                                                                period: .day,
                                                                quantity: 1,
                                                                latestDateToInclude: DateFormatter.dateFromString(with: "2022-12-09T17:06:55"),
                                                                saveInStorage: true) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSummaryStats.self), 1)

        let readOnlySiteSummaryStats = viewStorage.firstObject(ofType: Storage.SiteSummaryStats.self)?.toReadOnly()
        XCTAssertEqual(readOnlySiteSummaryStats, sampleSiteSummaryStats())
    }

    /// Verifies that `upsertStoredSiteSummaryStats` does not produce duplicate entries.
    ///
    func test_upsertStoredSiteSummaryStats_effectively_updates_preexistant_SiteSummaryStats() {
        let statsStore = StatsStoreV4(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertNil(viewStorage.loadSiteSummaryStats(date: "2022-12-09", period: StatGranularity.day.rawValue))
        statsStore.upsertStoredSiteSummaryStats(readOnlyStats: sampleSiteSummaryStats())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSummaryStats.self), 1)
        statsStore.upsertStoredSiteSummaryStats(readOnlyStats: sampleSiteSummaryStatsMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.SiteSummaryStats.self), 1)

        let expectedSiteSummaryStats = sampleSiteSummaryStatsMutated()
        let storageSiteSummaryStats = viewStorage.loadSiteSummaryStats(date: "2022-12-09", period: StatGranularity.day.rawValue)
        XCTAssertEqual(storageSiteSummaryStats?.toReadOnly(), expectedSiteSummaryStats)
    }
}


// MARK: - Private Methods
//
private extension StatsStoreV4Tests {
    // MARK: - Order Stats V4 Sample

    func sampleStats() -> Networking.OrderStatsV4 {
        return OrderStatsV4(siteID: sampleSiteID,
                            granularity: .monthly,
                            totals: sampleTotals(),
                            intervals: sampleIntervals())
    }


    /// Matches `totals` field in `order-stats-v4-year` response.
    func sampleTotals() -> Networking.OrderStatsV4Totals {
        return OrderStatsV4Totals(totalOrders: 3,
                                  totalItemsSold: 5,
                                  grossRevenue: 800,
                                  couponDiscount: 0,
                                  totalCoupons: 0,
                                  refunds: 0,
                                  taxes: 0,
                                  shipping: 0,
                                  netRevenue: 800,
                                  totalProducts: 2,
                                  averageOrderValue: 266)
    }

    /// Matches the first interval's `subtotals` field in `order-stats-v4-year` response.
    func sampleIntervalSubtotals() -> Networking.OrderStatsV4Totals {
        return OrderStatsV4Totals(totalOrders: 3,
                                  totalItemsSold: 5,
                                  grossRevenue: 800,
                                  couponDiscount: 0,
                                  totalCoupons: 0,
                                  refunds: 0,
                                  taxes: 0,
                                  shipping: 0,
                                  netRevenue: 800,
                                  totalProducts: 0,
                                  averageOrderValue: 266)
    }

    func sampleIntervals() -> [Networking.OrderStatsV4Interval] {
        return [sampleIntervalMonthly()]
    }

    func sampleIntervalMonthly() -> Networking.OrderStatsV4Interval {
        return OrderStatsV4Interval(interval: "2019",
                                    dateStart: "2019-07-09 00:00:00",
                                    dateEnd: "2019-07-09 23:59:59",
                                    subtotals: sampleIntervalSubtotals())
    }

    func sampleStatsMutated() -> Networking.OrderStatsV4 {
        return OrderStatsV4(siteID: sampleSiteID,
                            granularity: .yearly,
                            totals: sampleTotalsMutated(),
                            intervals: sampleIntervalsMutated())
    }

    func sampleIntervalsMutated() -> [Networking.OrderStatsV4Interval] {
        return [sampleIntervalYearMutated()]
    }

    func sampleIntervalYearMutated() -> Networking.OrderStatsV4Interval {
        return OrderStatsV4Interval(interval: "2019",
                                    dateStart: "2019-07-09 00:00:00",
                                    dateEnd: "2019-07-09 23:59:59",
                                    subtotals: sampleTotalsMutated())
    }

    func sampleTotalsMutated() -> Networking.OrderStatsV4Totals {
        return OrderStatsV4Totals(totalOrders: 10,
                                  totalItemsSold: 0,
                                  grossRevenue: 0,
                                  couponDiscount: 0,
                                  totalCoupons: 0,
                                  refunds: 0,
                                  taxes: 0,
                                  shipping: 0,
                                  netRevenue: 0,
                                  totalProducts: 0,
                                  averageOrderValue: 0)
    }

    // MARK: - Site Visit Stats Sample

    func sampleSiteVisitStats() -> Networking.SiteVisitStats {
        return SiteVisitStats(siteID: sampleSiteID,
                              date: "2015-08-06",
                              granularity: .year,
                              items: [sampleSiteVisitStatsItem1(), sampleSiteVisitStatsItem2()])
    }


    func sampleSiteVisitStatsItem1() -> Networking.SiteVisitStatsItem {
        return SiteVisitStatsItem(period: "2014-01-01", visitors: 1135, views: 12821)
    }

    func sampleSiteVisitStatsItem2() -> Networking.SiteVisitStatsItem {
        return SiteVisitStatsItem(period: "2015-01-01", visitors: 1629, views: 14808)
    }

    func sampleSiteVisitStatsMutated() -> Networking.SiteVisitStats {
        return SiteVisitStats(siteID: sampleSiteID,
                              date: "2015-08-06",
                              granularity: .year,
                              items: [sampleSiteVisitStatsItem1Mutated(), sampleSiteVisitStatsItem2Mutated()])
    }


    func sampleSiteVisitStatsItem1Mutated() -> Networking.SiteVisitStatsItem {
        return SiteVisitStatsItem(period: "2014-01-01", visitors: 1140, views: 12831)
    }

    func sampleSiteVisitStatsItem2Mutated() -> Networking.SiteVisitStatsItem {
        return SiteVisitStatsItem(period: "2015-01-01", visitors: 1634, views: 14818)
    }

    // MARK: - Top Earner Stats Sample

    func sampleTopEarnerStats() -> Networking.TopEarnerStats {
        return TopEarnerStats(siteID: sampleSiteID,
                              date: "2020",
                              granularity: .year,
                              limit: "3",
                              items: [sampleTopEarnerStatsItem1(), sampleTopEarnerStatsItem2()])
    }

    func sampleTopEarnerStatsItem1() -> Networking.TopEarnerStatsItem {
        return TopEarnerStatsItem(productID: 29,
                                  productName: "Album",
                                  quantity: 1,
                                  price: 15.0,
                                  total: 15.99,
                                  currency: "",
                                  imageUrl: "https://dulces.mystagingwebsite.com/wp-content/uploads/2020/06/album-1.jpg")
    }

    func sampleTopEarnerStatsItem2() -> Networking.TopEarnerStatsItem {
        return TopEarnerStatsItem(productID: 9,
                                  productName: "Aljafor",
                                  quantity: 4,
                                  price: 4000,
                                  total: 20000,
                                  currency: "",
                                  imageUrl: "https://dulces.mystagingwebsite.com/wp-content/uploads/2020/07/img_7472-scaled.jpeg")
    }

    func sampleTopEarnerStatsMutated() -> Networking.TopEarnerStats {
        return TopEarnerStats(siteID: sampleSiteID,
                              date: "2020",
                              granularity: .year,
                              limit: "3",
                              items: [sampleTopEarnerStatsMutatedItem1(), sampleTopEarnerStatsMutatedItem2()])
    }

    func sampleTopEarnerStatsMutatedItem1() -> Networking.TopEarnerStatsItem {
        return TopEarnerStatsItem(productID: 29,
                                  productName: "Album",
                                  quantity: 2,
                                  price: 15.0,
                                  total: 30.99,
                                  currency: "",
                                  imageUrl: "https://dulces.mystagingwebsite.com/wp-content/uploads/2020/06/album-1.jpg")
    }

    func sampleTopEarnerStatsMutatedItem2() -> Networking.TopEarnerStatsItem {
        return TopEarnerStatsItem(productID: 9,
                                  productName: "Aljafor",
                                  quantity: 10,
                                  price: 4000,
                                  total: 60000,
                                  currency: "",
                                  imageUrl: "https://dulces.mystagingwebsite.com/wp-content/uploads/2020/07/img_7472-scaled.jpeg")
    }

    // MARK: - Site Summary Stats Sample

    func sampleSiteSummaryStats() -> Networking.SiteSummaryStats {
        return SiteSummaryStats(siteID: sampleSiteID,
                                date: "2022-12-09",
                                period: .day,
                                visitors: 12,
                                views: 123)
    }

    func sampleSiteSummaryStatsMutated() -> Networking.SiteSummaryStats {
        return SiteSummaryStats(siteID: sampleSiteID,
                                date: "2022-12-09",
                                period: .day,
                                visitors: 15,
                                views: 127)
    }

    func sampleSiteSummaryStatsQuarter() -> Networking.SiteSummaryStats {
        return SiteSummaryStats(siteID: sampleSiteID,
                                date: "2022-12-09",
                                period: .month,
                                visitors: 243,
                                views: 486)
    }
}
