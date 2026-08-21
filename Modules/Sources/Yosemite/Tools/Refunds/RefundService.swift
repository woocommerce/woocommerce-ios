import Foundation
import Networking
import Storage
import CocoaLumberjackSwift
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite

/// Async interface to the server-calculated refund endpoints (`/wc/v3` preview and
/// `compute_totals` create, WC 11.1.0+). The classic v3 refund flows remain action-based via
/// `RefundStore`; both paths can migrate here together once the classic path is retired.
///
public protocol RefundServiceProtocol {
    /// Requests a server-calculated refund preview. Read-only: nothing is persisted.
    /// On stores where the route is not registered the request fails with
    /// `DotcomError.noRestRoute` (404 `rest_no_route`) — the signal callers use to fall back
    /// to locally calculated refunds.
    func previewRefund(siteID: Int64,
                       orderID: Int64,
                       lineItems: [RefundPreviewLineItem]) async throws -> RefundPreview

    /// Creates a refund via the `compute_totals` request (line items only; the server owns the
    /// math unless an explicit `amountOverride` is supplied). On success the returned refund is
    /// upserted to storage exactly like the classic `RefundAction.createRefund` path.
    ///
    /// SAFETY: call this only when the site's WooCommerce version supports the `compute_totals`
    /// create and a preview for the same selection succeeded. A preview alone proves only that the
    /// preview route exists. A store without support drops the parameter and creates a zero-amount
    /// refund with restock. `POSRefundFlowResolver` checks the version; `POSRefundSubmissionAdaptor`
    /// checks that this selection was previewed.
    func createRefund(siteID: Int64,
                      orderID: Int64,
                      reason: String,
                      automaticRefund: Bool,
                      restockItems: Bool,
                      amountOverride: String?,
                      lineItems: [ComputedRefundLineItem]) async throws -> Refund
}

public final class RefundService: RefundServiceProtocol {
    private let remote: RefundsRemoteProtocol
    private let upserter: RefundsUpserter

    public convenience init?(credentials: Credentials?,
                             selectedSite: AnyPublisher<JetpackSite?, Never>,
                             appPasswordSupportState: AnyPublisher<Bool, Never>,
                             storageManager: StorageManagerType) {
        guard let credentials else {
            DDLogError("⛔️ Could not create RefundService due to not finding credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.init(remote: RefundsRemote(network: network), storageManager: storageManager)
    }

    public init(remote: RefundsRemoteProtocol, storageManager: StorageManagerType) {
        self.remote = remote
        self.upserter = RefundsUpserter(storageManager: storageManager)
    }

    public func previewRefund(siteID: Int64,
                              orderID: Int64,
                              lineItems: [RefundPreviewLineItem]) async throws -> RefundPreview {
        try await remote.previewRefund(for: siteID, orderID: orderID, lineItems: lineItems)
    }

    public func createRefund(siteID: Int64,
                             orderID: Int64,
                             reason: String,
                             automaticRefund: Bool,
                             restockItems: Bool,
                             amountOverride: String?,
                             lineItems: [ComputedRefundLineItem]) async throws -> Refund {
        let refund = try await remote.createComputedRefund(for: siteID,
                                                           orderID: orderID,
                                                           reason: reason,
                                                           apiRefund: automaticRefund,
                                                           apiRestock: restockItems,
                                                           amountOverride: amountOverride,
                                                           lineItems: lineItems)
        await upserter.upsertStoredRefunds(siteID: siteID, orderID: orderID, readOnlyRefunds: [refund])
        return refund
    }
}
