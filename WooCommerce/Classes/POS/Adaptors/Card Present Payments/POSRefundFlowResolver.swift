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
/// - the `posRefundsV4` feature flag (the name predates the port of the endpoints to `/wc/v3`),
/// - the site not being cached as unavailable (a preview already returned `rest_no_route`),
/// - a successful preview having confirmed availability, or the cached WooCommerce version not
///   ruling the endpoints out (below ``Constants/minimumWooVersionForServerRefunds``); an unknown
///   version is not conclusive, so the preview probe decides.
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

    init(stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         availabilityCache: ServerRefundAvailabilityCache = .shared,
         minimumWooVersion: String = Constants.minimumWooVersionForServerRefunds) {
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.availabilityCache = availabilityCache
        self.minimumWooVersion = minimumWooVersion
    }

    func resolveFlow(siteID: Int64) -> POSRefundFlow {
        guard featureFlagService.isFeatureFlagEnabled(.posRefundsV4) else {
            return .localComputed
        }
        let cachedAvailability = availabilityCache.isAvailable(siteID: siteID)
        guard cachedAvailability != false,
              cachedAvailability == true || !isWooVersionBelowMinimum() else {
            return .localComputed
        }
        return .serverComputed
    }

    private func isWooVersionBelowMinimum() -> Bool {
        guard let version = stores.sessionManager.cachedWooCommerceVersion else {
            return false
        }
        return !VersionHelpers.isVersionSupported(version: version,
                                                  minimumRequired: minimumWooVersion,
                                                  includesDevAndBetaVersions: true)
    }

    enum Constants {
        /// The WooCommerce release that ships the `/wc/v3` refund preview and `compute_totals`
        /// create endpoints.
        static let minimumWooVersionForServerRefunds = "11.1.0"
    }
}
