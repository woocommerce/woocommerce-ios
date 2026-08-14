import Foundation
import Yosemite
import Experiments
import class WooFoundation.VersionHelpers

/// The two POS refund calculation flows.
enum POSRefundFlow: Equatable {
    /// Refund totals come from the server: `/wc/v3` preview + `compute_totals` create (WC 11.1.0+).
    case serverComputed

    /// Legacy flow: refund totals are calculated locally and submitted via the classic v3 create.
    /// Deletable once every supported store ships the server-calculated endpoints.
    case localComputed
}

/// Decides which refund calculation flow a site is eligible for.
///
/// `serverComputed` requires all of:
/// - the `posServerCalculatedRefunds` feature flag,
/// - the site not being cached as unavailable (a preview already returned `rest_no_route`),
/// - a cached WooCommerce version that is known and at least
///   ``Constants/minimumWooVersionForServerRefunds``; an unknown version fails closed to
///   `localComputed`.
///
/// The version requirement is authoritative for the create capability and cannot be bypassed by a
/// successful preview: the preview route and the `compute_totals` create support ship in separate
/// WooCommerce core changes, so a preview succeeding only proves the preview route exists. A store
/// with the preview but without `compute_totals` (partial backport, or the changes splitting
/// across releases) would silently drop the parameter and create a zero-amount refund while
/// restocking items. Only a version known to contain both changes unlocks the server flow.
///
/// Eligibility here only allows the *preview* probe. A computed create additionally requires that
/// probe to succeed first — see `ServerRefundAvailabilityCache`.
///
@MainActor
struct POSRefundFlowResolver {
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let availabilityCache: ServerRefundAvailabilityCache
    private let minimumWooVersion: String

    // Every dependency is explicit (no defaults) so a missing one is a compile error
    // rather than a silently picked service, per review.
    init(stores: StoresManager,
         featureFlagService: FeatureFlagService,
         availabilityCache: ServerRefundAvailabilityCache,
         minimumWooVersion: String) {
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.availabilityCache = availabilityCache
        self.minimumWooVersion = minimumWooVersion
    }

    func resolveFlow(siteID: Int64) -> POSRefundFlow {
        guard featureFlagService.isFeatureFlagEnabled(.posServerCalculatedRefunds) else {
            return .localComputed
        }
        guard availabilityCache.isAvailable(siteID: siteID) != false else {
            return .localComputed
        }
        guard isWooVersionAtLeastMinimum() else {
            return .localComputed
        }
        return .serverComputed
    }

    /// The WooCommerce version this resolver judged the site on, for reporting alongside a
    /// fallback so a store that fell back can be told apart from one that was never eligible.
    var cachedWooCommerceVersion: String? {
        stores.sessionManager.cachedWooCommerceVersion
    }

    private func isWooVersionAtLeastMinimum() -> Bool {
        // Unknown version fails closed: eligibility must never rest on the preview probe alone,
        // because the preview route does not prove `compute_totals` create support.
        guard let version = stores.sessionManager.cachedWooCommerceVersion else {
            return false
        }
        return VersionHelpers.isVersionSupported(version: version,
                                                 minimumRequired: minimumWooVersion,
                                                 includesDevAndBetaVersions: true)
    }

    enum Constants {
        /// The earliest WooCommerce core release containing both the `/wc/v3` refund preview
        /// route and the `compute_totals` create support.
        static let minimumWooVersionForServerRefunds = "11.1.0"
    }
}
