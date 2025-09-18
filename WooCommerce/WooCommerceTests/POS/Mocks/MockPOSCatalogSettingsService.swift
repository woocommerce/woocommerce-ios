@testable import Yosemite

final class MockPOSCatalogSettingsService: POSCatalogSettingsServiceProtocol {
    var catalogStatisticsResult: Result<POSCatalogStatistics, Error> = .success(POSCatalogStatistics(productCount: 0, variationCount: 0))
    var syncDatesResult: Result<POSSyncDates, Error> = .success(POSSyncDates(lastFullSyncDate: nil, lastIncrementalSyncDate: nil))
    var shouldDelayResponse = false

    func loadCatalogStatistics(for siteID: Int64) async throws -> POSCatalogStatistics {
        if shouldDelayResponse {
            try await Task.sleep(for: .milliseconds(100))
        }

        switch catalogStatisticsResult {
        case .success(let statistics):
            return statistics
        case .failure(let error):
            throw error
        }
    }

    func loadSyncDates(for siteID: Int64) async throws -> POSSyncDates {
        if shouldDelayResponse {
            try await Task.sleep(for: .milliseconds(50))
        }

        switch syncDatesResult {
        case .success(let dates):
            return dates
        case .failure(let error):
            throw error
        }
    }
}
