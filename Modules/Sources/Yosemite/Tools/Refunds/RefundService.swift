import Foundation
import Networking
import Storage
import CocoaLumberjackSwift
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite

/// Async interface to the server-calculated refund endpoints. Carries both generations while
/// the POS flow migrates: the v4 endpoints (WC 10.9.0+ behind the server `rest-api-v4` flag)
/// and their `/wc/v3` replacements (WC 11.1.0+, production). The classic refund flows remain
/// action-based via `RefundStore`. The v4 pair is removed once the flow switches.
///
public protocol RefundServiceProtocol {
    /// Requests a server-calculated refund preview. Read-only: nothing is persisted.
    /// On stores where the route is not registered the request fails with
    /// `DotcomError.noRestRoute` (404 `rest_no_route`) — the signal callers use to fall back to v3.
    func previewRefund(siteID: Int64,
                       orderID: Int64,
                       lineItems: [RefundV4LineItem]) async throws -> RefundPreview

    /// Creates a refund via the simplified v4 request (line items only, no client-calculated
    /// `amount`; the server owns the math). On success the returned refund is upserted to
    /// storage exactly like the v3 `RefundAction.createRefund` path.
    func createRefund(siteID: Int64,
                      orderID: Int64,
                      reason: String,
                      automaticRefund: Bool,
                      restockItems: Bool,
                      lineItems: [RefundV4LineItem]) async throws -> Refund

    /// Requests a server-calculated refund preview via `/wc/v3` (WC 11.1.0+). Read-only:
    /// nothing is persisted. On stores where the route is not registered the request fails with
    /// `DotcomError.noRestRoute` (404 `rest_no_route`) — the signal callers use to fall back
    /// to locally calculated refunds.
    func previewRefund(siteID: Int64,
                       orderID: Int64,
                       lineItems: [RefundPreviewLineItem]) async throws -> RefundPreview

    /// Creates a refund via the `compute_totals` request (line items only; the server owns the
    /// math unless an explicit `amount` override is supplied). On success the returned refund is
    /// upserted to storage exactly like the classic `RefundAction.createRefund` path.
    ///
    /// SAFETY: must only be called after a successful `previewRefund` confirmed server-calculated
    /// refund support for the site — older stores silently drop `compute_totals` and would create
    /// a ghost zero-amount refund with restock from a quantity-only body.
    func createRefund(siteID: Int64,
                      orderID: Int64,
                      reason: String,
                      automaticRefund: Bool,
                      restockItems: Bool,
                      amount: String?,
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
                              lineItems: [RefundV4LineItem]) async throws -> RefundPreview {
        try await remote.previewRefund(for: siteID, orderID: orderID, lineItems: lineItems)
    }

    public func createRefund(siteID: Int64,
                             orderID: Int64,
                             reason: String,
                             automaticRefund: Bool,
                             restockItems: Bool,
                             lineItems: [RefundV4LineItem]) async throws -> Refund {
        let refund = try await remote.createRefundV4(for: siteID,
                                                     orderID: orderID,
                                                     reason: reason,
                                                     automaticRefund: automaticRefund,
                                                     restockItems: restockItems,
                                                     lineItems: lineItems)
        await upserter.upsertStoredRefunds(siteID: siteID, orderID: orderID, readOnlyRefunds: [refund])
        return refund
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
                             amount: String?,
                             lineItems: [ComputedRefundLineItem]) async throws -> Refund {
        let refund = try await remote.createComputedRefund(for: siteID,
                                                           orderID: orderID,
                                                           reason: reason,
                                                           apiRefund: automaticRefund,
                                                           apiRestock: restockItems,
                                                           amount: amount,
                                                           lineItems: lineItems)
        await upserter.upsertStoredRefunds(siteID: siteID, orderID: orderID, readOnlyRefunds: [refund])
        return refund
    }
}
