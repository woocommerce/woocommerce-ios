import Combine
import Foundation
import Yosemite

/// Checks the ready status of store creation once the store has been created.
final class StoreCreationStatusChecker {
    private let stores: StoresManager
    private let jetpackCheckRetryInterval: TimeInterval

    convenience init(isFreeTrialCreation: Bool,
         stores: StoresManager = ServiceLocator.stores) {
        self.init(jetpackCheckRetryInterval: isFreeTrialCreation ? 10 : 5, stores: stores)
    }

    init(jetpackCheckRetryInterval: TimeInterval, stores: StoresManager) {
        self.jetpackCheckRetryInterval = jetpackCheckRetryInterval
        self.stores = stores
    }

    /// Waits for the site to have both Jetpack and WooCommerce plugins active, and the loads the latest site afterward.
    /// - Parameter siteID: WPCOM ID of the created site.
    /// - Returns: An observable value of either the created site when it's ready or an error.
    @MainActor
    func waitForSiteToBeReady(siteID: Int64) -> AnyPublisher<Site, Error> {
        Just(siteID)
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
        let arePluginsActive = try await areJetpackAndWooPluginsActive(siteID: siteID)

        guard arePluginsActive else {
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
    func areJetpackAndWooPluginsActive(siteID: Int64) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(SitePluginAction.arePluginsActive(siteID: siteID, plugins: [.jetpack, .woo]) { result in
                continuation.resume(with: result)
            })
        }
    }
}
