import Foundation
import Yosemite
import Experiments
import enum NetworkingCore.DotcomError
import enum NetworkingCore.NetworkError
import class WooFoundation.VersionHelpers

@MainActor
final class POSV4RefundPreviewUseCase {

    enum Result: Equatable {
        case serverCalculated(RefundPreview)
        case fallbackToLocal
        case error
    }

    typealias SiteAPILoader = @MainActor (Int64) async throws -> SiteAPI

    private let refundService: RefundServiceProtocol
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let availabilityCache: V4RefundAvailabilityCache
    private let minimumWooVersion: String
    private let siteAPILoader: SiteAPILoader
    private var routeSeedingTasks: [Int64: Task<Void, Never>] = [:]

    init(refundService: RefundServiceProtocol,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         availabilityCache: V4RefundAvailabilityCache = .shared,
         minimumWooVersion: String = Constants.minimumWooVersion,
         siteAPILoader: SiteAPILoader? = nil) {
        self.refundService = refundService
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.availabilityCache = availabilityCache
        self.minimumWooVersion = minimumWooVersion
        self.siteAPILoader = siteAPILoader ?? Self.makeSiteAPILoader(stores: stores)
    }

    /// Marks v4 available when the site's REST index lists the v4 refund routes, which only register
    /// when the server `rest-api-v4` flag is enabled — a reliable *positive* signal that beats a stale
    /// cached WooCommerce version. Route absence or an index fetch failure writes nothing: security
    /// plugins can filter the index, so the preview probe's 404 remains the only negative signal.
    /// At most one index fetch per site per session, off the preview's critical path.
    func seedAvailabilityFromSiteRoutesIfNeeded(siteID: Int64) async {
        guard featureFlagService.isFeatureFlagEnabled(.posRefundsV4),
              availabilityCache.isV4Available(siteID: siteID) == nil else {
            return
        }

        if let seedingTask = routeSeedingTasks[siteID] {
            return await seedingTask.value
        }

        let seedingTask = Task {
            do {
                let siteAPI = try await siteAPILoader(siteID)
                if siteAPI.hasV4RefundsRoutes {
                    availabilityCache.markV4Available(siteID: siteID)
                }
            } catch {
                DDLogError("⛔️ Could not check the site REST index for v4 refund routes: \(error)")
            }
        }
        routeSeedingTasks[siteID] = seedingTask
        await seedingTask.value
    }

    func previewRefund(siteID: Int64, orderID: Int64, lineItems: [RefundV4LineItem]) async -> Result {
        let cachedAvailability = availabilityCache.isV4Available(siteID: siteID)
        guard featureFlagService.isFeatureFlagEnabled(.posRefundsV4),
              lineItems.isNotEmpty,
              cachedAvailability != false,
              cachedAvailability == true || !isWooVersionBelowV4Support() else {
            return .fallbackToLocal
        }

        do {
            let preview = try await refundService.previewRefund(siteID: siteID, orderID: orderID, lineItems: lineItems)
            availabilityCache.markV4Available(siteID: siteID)
            return .serverCalculated(preview)
        } catch {
            if isRouteNotRegistered(error) {
                availabilityCache.markV4Unavailable(siteID: siteID)
                return .fallbackToLocal
            }
            return .error
        }
    }

    private func isWooVersionBelowV4Support() -> Bool {
        guard let version = stores.sessionManager.cachedWooCommerceVersion else {
            return false
        }
        return !VersionHelpers.isVersionSupported(version: version,
                                                  minimumRequired: minimumWooVersion,
                                                  includesDevAndBetaVersions: true)
    }

    private func isRouteNotRegistered(_ error: Error) -> Bool {
        if let dotcomError = error as? DotcomError, case .noRestRoute = dotcomError {
            return true
        }
        if let networkError = error as? NetworkError, case .notFound = networkError, networkError.errorCode == "rest_no_route" {
            return true
        }
        return false
    }

    private static func makeSiteAPILoader(stores: StoresManager) -> SiteAPILoader {
        { siteID in
            try await withCheckedThrowingContinuation { continuation in
                let action = SettingAction.retrieveSiteAPI(siteID: siteID) { result in
                    continuation.resume(with: result)
                }
                stores.dispatch(action)
            }
        }
    }

    private enum Constants {
        static let minimumWooVersion = "10.9.0"
    }
}

private extension SiteAPI {
    /// The v4 refund routes (`/wc/v4/refunds`, `/wc/v4/refunds/preview`) register only when the
    /// server `rest-api-v4` feature flag is enabled.
    var hasV4RefundsRoutes: Bool {
        routes.contains { $0.hasPrefix(Constants.v4RefundsRoutePrefix) }
    }

    enum Constants {
        static let v4RefundsRoutePrefix = "/wc/v4/refunds"
    }
}
