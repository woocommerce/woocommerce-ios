import Foundation
import Yosemite
import Experiments
import enum NetworkingCore.DotcomError
import enum NetworkingCore.NetworkError
import class WooFoundation.VersionHelpers

/// Detects whether the store exposes the WooCommerce v4 refund endpoints and, when it does, returns
/// a server-calculated refund preview. Otherwise it falls back to the existing v3 + local-calculation
/// flow, leaving the merchant experience unchanged.
///
/// Gating order (cheapest first):
/// 1. `posRefundsV4` feature flag off → fall back (no network).
/// 2. v4 already cached unavailable for this site → fall back (no network).
/// 3. not yet probed and the cached WooCommerce version is older than 10.9.0 (where v4 shipped)
///    → fall back without touching the availability cache: the version string is only a cheap,
///    possibly-stale hint, so the probe stays the single authority on availability, and a
///    server-confirmed site skips this check entirely.
/// 4. no line items to preview → fall back.
/// 5. probe `POST wc/v4/refunds/preview`: a `rest_no_route` response marks v4 unavailable and falls
///    back; any other error is surfaced as `.error`; success caches availability and returns totals.
///
@MainActor
final class POSV4RefundPreviewUseCase {

    enum Result: Equatable {
        /// The server returned authoritative totals; display them as-is.
        case serverCalculated(RefundPreview)
        /// v4 isn't available; use the existing v3 + local-calculation flow.
        case fallbackToLocal
        /// The preview failed for a recoverable reason; the caller should offer a retry.
        case error
    }

    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let availabilityCache: V4RefundAvailabilityCache
    private let minimumWooVersion: String

    /// The `.shared` default argument touches MainActor-isolated state; that's safe because default
    /// arguments are evaluated at the call site and every caller of this MainActor-isolated
    /// initializer is itself MainActor-isolated.
    init(stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         availabilityCache: V4RefundAvailabilityCache = .shared,
         minimumWooVersion: String = Constants.minimumWooVersion) {
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.availabilityCache = availabilityCache
        self.minimumWooVersion = minimumWooVersion
    }

    func previewRefund(siteID: Int64, orderID: Int64, lineItems: [RefundV4LineItem]) async -> Result {
        guard featureFlagService.isFeatureFlagEnabled(.posRefundsV4) else {
            return .fallbackToLocal
        }

        let cachedAvailability = availabilityCache.isV4Available(siteID: siteID)
        if cachedAvailability == false {
            return .fallbackToLocal
        }

        if cachedAvailability == nil, isWooVersionBelowV4Support() {
            return .fallbackToLocal
        }

        guard lineItems.isNotEmpty else {
            return .fallbackToLocal
        }

        switch await dispatchPreview(siteID: siteID, orderID: orderID, lineItems: lineItems) {
        case .success(let preview):
            availabilityCache.markV4Available(siteID: siteID)
            return .serverCalculated(preview)
        case .failure(let error):
            if isRouteNotRegistered(error) {
                availabilityCache.markV4Unavailable(siteID: siteID)
                return .fallbackToLocal
            }
            return .error
        }
    }

    private func isWooVersionBelowV4Support() -> Bool {
        // A missing cached version isn't conclusive, so don't skip the probe on it.
        guard let version = stores.sessionManager.cachedWooCommerceVersion else {
            return false
        }
        // Include dev/beta versions so a `10.9.0-beta`/`-rc` store isn't treated as below 10.9.0
        // (same choice as `POSTabEligibilityChecker`).
        return !VersionHelpers.isVersionSupported(version: version,
                                                  minimumRequired: minimumWooVersion,
                                                  includesDevAndBetaVersions: true)
    }

    /// `true` only when the store genuinely doesn't register the v4 route (`rest_no_route`), so a
    /// transient per-order error never disables v4 for the rest of the session. Covers both the
    /// Jetpack-tunneled (`DotcomError`) and direct REST (`NetworkError`) code paths.
    private func isRouteNotRegistered(_ error: Error) -> Bool {
        if let dotcomError = error as? DotcomError, case .noRestRoute = dotcomError {
            return true
        }
        if let networkError = error as? NetworkError, case .notFound = networkError, networkError.errorCode == "rest_no_route" {
            return true
        }
        return false
    }

    private func dispatchPreview(siteID: Int64,
                                 orderID: Int64,
                                 lineItems: [RefundV4LineItem]) async -> Swift.Result<RefundPreview, Error> {
        await withCheckedContinuation { continuation in
            let action = RefundAction.previewRefund(siteID: siteID, orderID: orderID, lineItems: lineItems) { result in
                continuation.resume(returning: result)
            }
            stores.dispatch(action)
        }
    }

    private enum Constants {
        static let minimumWooVersion = "10.9.0"
    }
}
