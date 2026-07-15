import Foundation
import Networking


/// RefundAction: Defines all of the Actions supported by the RefundStore.
///
public enum RefundAction: Action {
    case createRefund(siteID: Int64, orderID: Int64, refund: Refund, onCompletion: (Refund?, Error?) -> Void)

    /// Requests a server-calculated refund preview via the v4 endpoint. When the v4 route is
    /// unavailable the failure is `DotcomError.noRestRoute` (Jetpack-tunneled requests) or
    /// `NetworkError.notFound` carrying the `rest_no_route` error code (direct REST /
    /// application-password sites) — check both when falling back to v3.
    case previewRefund(siteID: Int64, orderID: Int64, lineItems: [RefundV4LineItem], onCompletion: (Result<RefundPreview, Error>) -> Void)

    /// Creates a refund via the simplified v4 endpoint, sending only the items to refund (no
    /// client-calculated amount). Fails like `previewRefund` when v4 is unavailable. The v4
    /// response carries no display fields (item names/prices), so the upserted refund is skeletal —
    /// follow up with `retrieveRefund` before rendering it from storage.
    case createRefundV4(siteID: Int64,
                        orderID: Int64,
                        reason: String,
                        automaticRefund: Bool,
                        restockItems: Bool,
                        lineItems: [RefundV4LineItem],
                        onCompletion: (Result<Refund, Error>) -> Void)
    case retrieveRefund(siteID: Int64, orderID: Int64, refundID: Int64, onCompletion: (Refund?, Error?) -> Void)
    case retrieveRefunds(siteID: Int64, orderID: Int64, refundIDs: [Int64], deleteStaleRefunds: Bool, onCompletion: (Error?) -> Void)
    case synchronizeRefunds(siteID: Int64, orderID: Int64, pageNumber: Int, pageSize: Int, onCompletion: (Error?) -> Void)
    case resetStoredRefunds(onCompletion: () -> Void)
}
