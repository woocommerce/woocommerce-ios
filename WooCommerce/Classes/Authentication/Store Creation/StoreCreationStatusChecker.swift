import Combine
import Foundation
import Yosemite
import protocol Storage.StorageManagerType

final class StoreCreationStatusChecker {
    private let stores: StoresManager
    private let isFreeTrialCreation: Bool
    private let jetpackCheckRetryInterval: TimeInterval

    @Published private var siteIDFromStoreCreation: Int64?

    init(isFreeTrialCreation: Bool,
         stores: StoresManager = ServiceLocator.stores) {
        self.isFreeTrialCreation = isFreeTrialCreation
        self.jetpackCheckRetryInterval = isFreeTrialCreation ? 10 : 5
        self.stores = stores
    }

    @MainActor
    func waitForSiteToBeReady(siteID: Int64) -> AnyPublisher<Site, Error> {
        /// Free trial sites need more waiting time that regular sites.
        ///
        siteIDFromStoreCreation = siteID

        return $siteIDFromStoreCreation
            .compactMap { $0 }
            .removeDuplicates()
            .asyncMap { [weak self] siteID -> Site? in
                guard let self else {
                    return nil
                }
                // Waits some seconds before syncing sites every time.
                try await Task.sleep(nanoseconds: UInt64(self.jetpackCheckRetryInterval * 1_000_000_000))
                return try await self.syncSite(siteID: siteID)
            }
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

private extension StoreCreationStatusChecker {
    @MainActor
    func syncSite(siteID: Int64) async throws -> Site {
        let isJetpackActive = try await isJetpackPluginActive(siteID: siteID)

        guard isJetpackActive else {
            DDLogInfo("🔵 Retrying: Site available but is not a jetpack site yet for siteID \(siteID)...")
            throw StoreCreationError.newSiteIsNotJetpackSite
        }

        let site = try await loadSite(siteID: siteID)
        return site
    }
}

private extension StoreCreationStatusChecker {
    @MainActor
    func loadSite(siteID: Int64) async throws -> Site {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(SiteAction.syncSite(siteID: siteID) { result in
                continuation.resume(with: result)
            })
        }
    }

    @MainActor
    func isJetpackPluginActive(siteID: Int64) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(SitePluginAction.isPluginActive(siteID: siteID, plugin: .jetpack) { result in
                continuation.resume(with: result)
            })
        }
    }
}
