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
    /// SAFETY: must only be called after a successful `previewRefund` confirmed server-calculated
    /// refund support for the site — older stores silently drop `compute_totals` and would create
    /// a ghost zero-amount refund with restock from a quantity-only body. That outcome is detected
    /// after the fact and thrown as `RefundServiceError.ghostRefundDetected` rather than returned
    /// as a success; see `createRefund`'s implementation.
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
        if Self.hasGhostRefundSignature(requestedLineItems: lineItems, createdRefund: refund) {
            DDLogError("⛔️ Ghost refund detected on order \(orderID): quantity-based lines were sent but the store "
                       + "created refund \(refund.refundID) for \(refund.amount). The store most likely dropped "
                       + "`compute_totals`, so the items may have been restocked without any money moving.")
            // Deliberately not upserted: this is not a refund the merchant asked for, and treating it
            // as a success would show a completed refund for money that never moved. The record does
            // exist on the store, so it appears on the next order sync.
            throw RefundServiceError.ghostRefundDetected(refundID: refund.refundID, amount: refund.amount)
        }
        await upserter.upsertStoredRefunds(siteID: siteID, orderID: orderID, readOnlyRefunds: [refund])
        return refund
    }

    /// The signature of a `compute_totals` request handled by a store that does not support it:
    /// quantity-based lines carry no monetary value, so the classic create sums the absent per-line
    /// `refund_total`s to zero and books a refund for nothing while still restocking.
    ///
    /// Amount-based lines cannot produce this, because they carry their own `refund_total`.
    ///
    /// Known false positive: refunding only zero-priced lines legitimately computes to 0.00. That
    /// refund is a no-op either way, so failing it is the safer side of the trade.
    ///
    private static func hasGhostRefundSignature(requestedLineItems: [ComputedRefundLineItem],
                                                createdRefund: Refund) -> Bool {
        guard requestedLineItems.contains(where: { $0.quantity != nil }) else {
            return false
        }
        // POSIX locale: the API emits canonical decimal strings, never locale-formatted ones.
        // A nil parse means we cannot prove the amount is zero, so the tripwire stays silent.
        guard let amount = Decimal(string: createdRefund.amount, locale: Locale(identifier: "en_US_POSIX")) else {
            return false
        }
        return amount == .zero
    }
}

/// Failures raised by `RefundService` itself, rather than relayed from the network layer.
///
public enum RefundServiceError: Error, Equatable {
    /// A `compute_totals` create came back as a zero-amount refund despite quantity-based lines
    /// being requested — the signature of a store that silently ignored `compute_totals`.
    /// The refund exists on the store and the items may have been restocked, but no money moved.
    case ghostRefundDetected(refundID: Int64, amount: String)
}
