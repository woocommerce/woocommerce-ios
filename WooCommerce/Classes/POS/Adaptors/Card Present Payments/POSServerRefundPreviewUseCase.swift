import Foundation
import Yosemite
import Experiments
import WooFoundation
import enum NetworkingCore.DotcomError
import enum NetworkingCore.NetworkError

/// Requests a server-calculated refund preview when the site is eligible for the
/// server-computed flow, falling back to local calculations otherwise.
///
/// The preview doubles as the availability probe: a success marks the site available in the
/// `ServerRefundAvailabilityCache` (the precondition for sending a `compute_totals` create),
/// while a 404 `rest_no_route` marks it unavailable and falls back without surfacing an error.
///
@MainActor
final class POSServerRefundPreviewUseCase {

    enum Result: Equatable {
        case serverCalculated(RefundPreview)
        case fallbackToLocal
        case error
    }

    private let refundService: RefundServiceProtocol
    private let flowResolver: POSRefundFlowResolver
    private let availabilityCache: ServerRefundAvailabilityCache

    init(refundService: RefundServiceProtocol,
         flowResolver: POSRefundFlowResolver,
         availabilityCache: ServerRefundAvailabilityCache) {
        self.refundService = refundService
        self.flowResolver = flowResolver
        self.availabilityCache = availabilityCache
    }

    convenience init(refundService: RefundServiceProtocol,
                     stores: StoresManager = ServiceLocator.stores,
                     featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
                     availabilityCache: ServerRefundAvailabilityCache = .shared,
                     minimumWooVersion: String = POSRefundFlowResolver.Constants.minimumWooVersionForServerRefunds) {
        self.init(refundService: refundService,
                  flowResolver: POSRefundFlowResolver(stores: stores,
                                                      featureFlagService: featureFlagService,
                                                      availabilityCache: availabilityCache,
                                                      minimumWooVersion: minimumWooVersion),
                  availabilityCache: availabilityCache)
    }

    func previewRefund(siteID: Int64, orderID: Int64, lineItems: [RefundPreviewLineItem]) async -> Result {
        guard lineItems.isNotEmpty,
              flowResolver.resolveFlow(siteID: siteID) == .serverComputed else {
            return .fallbackToLocal
        }

        do {
            let preview = try await refundService.previewRefund(siteID: siteID, orderID: orderID, lineItems: lineItems)
            availabilityCache.markAvailable(siteID: siteID)
            return .serverCalculated(preview)
        } catch {
            if isRouteNotRegistered(error) {
                availabilityCache.markUnavailable(siteID: siteID)
                return .fallbackToLocal
            }
            return .error
        }
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
}
