import Foundation
@testable import Yosemite

final class MockPOSCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    var performFullSyncInvocationCount = 0
    var performFullSyncSiteID: Int64?
    var performFullSyncResult: Result<Void, Error> = .success(())
    var lastSyncDate: Date?

    var performIncrementalSyncInvocationCount = 0
    var performIncrementalSyncSiteID: Int64?
    var performIncrementalSyncMaxAge: TimeInterval?
    var performIncrementalSyncResult: Result<Void, Error> = .success(())
    var onPerformIncrementalSyncCalled: (() -> Void)?

    var performSmartSyncInvocationCount = 0
    var performSmartSyncSiteID: Int64?
    var performSmartSyncFullSyncMaxAge: TimeInterval?
    var performSmartSyncIncrementalSyncMaxAge: TimeInterval?
    var performSmartSyncResult: Result<Void, Error> = .success(())

    var onPerformFullSyncCalled: (() -> Void)?

    func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval, regenerateCatalog: Bool, isBackgroundSync: Bool) async throws {
        performFullSyncInvocationCount += 1
        performFullSyncSiteID = siteID

        onPerformFullSyncCalled?()

        switch performFullSyncResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func performIncrementalSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {
        performIncrementalSyncInvocationCount += 1
        performIncrementalSyncSiteID = siteID
        performIncrementalSyncMaxAge = maxAge
        onPerformIncrementalSyncCalled?()

        switch performIncrementalSyncResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval, incrementalSyncMaxAge: TimeInterval, isBackgroundSync: Bool) async throws {
        performSmartSyncInvocationCount += 1
        performSmartSyncSiteID = siteID
        performSmartSyncFullSyncMaxAge = fullSyncMaxAge
        performSmartSyncIncrementalSyncMaxAge = incrementalSyncMaxAge

        switch performSmartSyncResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    let fullSyncStateModel = POSCatalogSyncStateModel()

    func loadLastFullSyncState(for siteID: Int64) async -> POSCatalogSyncState {
        return fullSyncStateModel.state[siteID] ?? .syncNeverDone(siteID: siteID)
    }

    var isSyncStaleResult: Bool = false

    func isSyncStale(for siteID: Int64, maxDays: Int) async -> Bool {
        return isSyncStaleResult
    }

    var hoursSinceLastSyncResult: Int? = nil

    func hoursSinceLastSync(for siteID: Int64) async -> Int? {
        return hoursSinceLastSyncResult
    }

    func stopOngoingSyncs(for siteID: Int64) async {}

    var processBackgroundDownloadResult: Result<Void, Error> = .success(())
    private(set) var processBackgroundDownloadCallCount = 0
    private(set) var lastProcessedFileURL: URL?
    private(set) var lastProcessedSiteID: Int64?

    func processBackgroundDownload(fileURL: URL, siteID: Int64) async throws {
        processBackgroundDownloadCallCount += 1
        lastProcessedFileURL = fileURL
        lastProcessedSiteID = siteID

        switch processBackgroundDownloadResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func deleteProductsFromCatalog(_ productIDs: [Int64], variationIDs: [Int64], siteID: Int64) async throws {
        // no-op
    }
}
