import CocoaLumberjackSwift
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
/// `ServerRefundAvailabilityCache` and returns the total that `POSRefundSubmissionAdaptor` keys by
/// selection — that stored total, not the cache, is what admits a `compute_totals` create. A 404
/// `rest_no_route` marks the site unavailable and falls back without surfacing an error.
///
@MainActor
final class POSServerRefundPreviewUseCase {

    enum Result {
        case serverCalculated(RefundPreview)
        case fallbackToLocal
        /// The server rejected the requested refund with an actionable code (for example the
        /// order changed since the screen was loaded); the rejection carries cashier-facing copy.
        case rejected(RefundAPIError)
        /// The preview failed for a reason with no cashier-facing mapping: a transport failure, or
        /// a server error whose code we do not recognise. The error is carried so the cause is
        /// attributable in logs rather than collapsing every failure into one indistinguishable
        /// state.
        case error(Error)
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

    func previewRefund(siteID: Int64, orderID: Int64, lineItems: [RefundPreviewLineItem]) async -> Result {
        guard lineItems.isNotEmpty else {
            return .fallbackToLocal
        }
        guard flowResolver.resolveFlow(siteID: siteID) == .serverComputed else {
            DDLogInfo("ℹ️ POS refund preview: site \(siteID) not eligible for the server flow; using local calculation")
            return .fallbackToLocal
        }

        do {
            let preview = try await refundService.previewRefund(siteID: siteID, orderID: orderID, lineItems: lineItems)
            availabilityCache.markAvailable(siteID: siteID)
            return .serverCalculated(preview)
        } catch {
            if isRouteNotRegistered(error) {
                DDLogInfo("ℹ️ POS refund preview route not registered on site \(siteID); falling back to local calculation")
                availabilityCache.markUnavailable(siteID: siteID)
                return .fallbackToLocal
            }
            if let rejection = RefundAPIError(error) {
                DDLogWarn("POS refund preview rejected for order \(orderID): \(rejection)")
                return .rejected(rejection)
            }
            DDLogError("⛔️ POS refund preview failed for order \(orderID): \(error)")
            return .error(error)
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

extension POSServerRefundPreviewUseCase.Result: Equatable {
    /// Two failures compare equal regardless of the underlying error: the payload is carried for
    /// logging, not to distinguish one failure from another.
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.serverCalculated(lhsPreview), .serverCalculated(rhsPreview)):
            return lhsPreview == rhsPreview
        case (.fallbackToLocal, .fallbackToLocal):
            return true
        case let (.rejected(lhsRejection), .rejected(rhsRejection)):
            return lhsRejection == rhsRejection
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}
