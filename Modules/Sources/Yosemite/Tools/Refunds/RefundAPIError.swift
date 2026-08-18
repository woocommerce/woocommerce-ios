import Foundation
import enum NetworkingCore.DotcomError
import enum NetworkingCore.NetworkError

/// A refund rejection returned by the server-calculated refund endpoints
/// (`POST /wc/v3/orders/{id}/refunds/preview` and `POST /wc/v3/orders/{id}/refunds` with
/// `compute_totals`) as a `woocommerce_rest_`-prefixed error code with a 400/422 status.
///
/// Only codes a cashier can act on are mapped — they occur when the order changed after the
/// screen was loaded (for example another register refunded part of the order). Codes that
/// indicate a client-side programming error (`invalid_line_item`, `invalid_quantity`,
/// `invalid_refund_total`, `missing_quantity_or_refund_total`, `duplicate_line_item`,
/// `line_item_not_found`, `missing_line_items`) are intentionally unmapped so they keep the
/// generic error path.
///
public enum RefundAPIError: Error, Equatable {
    /// `quantity_exceeds_refundable`: the selected quantity exceeds what is still refundable for that line.
    case quantityExceedsRefundable

    /// `line_item_already_refunded`: the line is already fully refunded.
    case lineItemAlreadyRefunded

    /// `order_not_refundable`: the order status does not allow refunds, or nothing refundable remains.
    case orderNotRefundable

    /// `preview_exceeds_max_refundable` / `refund_exceeds_remaining`: the requested total exceeds
    /// the order's remaining refundable amount.
    case refundExceedsRemaining

    /// `refund_total_exceeds_line`: the requested amount exceeds what is left on that line.
    case refundTotalExceedsLine

    /// `invalid_refund_amount`: non-positive or otherwise invalid refund total.
    case invalidRefundAmount

    /// Maps a refund endpoint failure to a typed rejection, or `nil` when the error does not
    /// carry one of the mapped codes. `rest_no_route` is deliberately not mapped so the
    /// route-availability fallback keeps working unchanged.
    public init?(_ error: Error) {
        let code: String?
        if let dotcomError = error as? DotcomError, case .unknown(let errorCode, _, _) = dotcomError {
            code = errorCode
        } else if let networkError = error as? NetworkError {
            code = networkError.errorCode
        } else {
            code = nil
        }
        guard let code, let rejection = Self.rejectionsByCode[code] else {
            return nil
        }
        self = rejection
    }

    private static let rejectionsByCode: [String: RefundAPIError] = [
        "woocommerce_rest_quantity_exceeds_refundable": .quantityExceedsRefundable,
        "woocommerce_rest_line_item_already_refunded": .lineItemAlreadyRefunded,
        "woocommerce_rest_order_not_refundable": .orderNotRefundable,
        "woocommerce_rest_preview_exceeds_max_refundable": .refundExceedsRemaining,
        "woocommerce_rest_refund_exceeds_remaining": .refundExceedsRemaining,
        "woocommerce_rest_refund_total_exceeds_line": .refundTotalExceedsLine,
        "woocommerce_rest_invalid_refund_amount": .invalidRefundAmount
    ]
}

extension RefundAPIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .quantityExceedsRefundable:
            return Localization.quantityExceedsRefundable
        case .lineItemAlreadyRefunded:
            return Localization.lineItemAlreadyRefunded
        case .orderNotRefundable:
            return Localization.orderNotRefundable
        case .refundExceedsRemaining:
            return Localization.refundExceedsRemaining
        case .refundTotalExceedsLine:
            return Localization.refundTotalExceedsLine
        case .invalidRefundAmount:
            return Localization.invalidRefundAmount
        }
    }

    private enum Localization {
        static let quantityExceedsRefundable = NSLocalizedString(
            "refundAPIError.quantityExceedsRefundable",
            value: "The selected quantity is more than what's left to refund.",
            comment: "Error shown when a refund is rejected because the selected quantity exceeds what is still refundable for an item."
        )
        static let lineItemAlreadyRefunded = NSLocalizedString(
            "refundAPIError.lineItemAlreadyRefunded",
            value: "This item has already been fully refunded.",
            comment: "Error shown when a refund is rejected because the selected item is already fully refunded."
        )
        static let orderNotRefundable = NSLocalizedString(
            "refundAPIError.orderNotRefundable",
            value: "This order can't be refunded.",
            comment: "Error shown when a refund is rejected because the order status does not allow refunds or nothing refundable remains."
        )
        static let refundExceedsRemaining = NSLocalizedString(
            "refundAPIError.refundExceedsRemaining",
            value: "The refund amount is more than what's left to refund on this order.",
            comment: "Error shown when a refund is rejected because the requested total exceeds the order's remaining refundable amount."
        )
        static let refundTotalExceedsLine = NSLocalizedString(
            "refundAPIError.refundTotalExceedsLine",
            value: "The refund amount is more than what's left to refund for this item.",
            comment: "Error shown when a refund is rejected because the requested amount exceeds what is left to refund on an item."
        )
        static let invalidRefundAmount = NSLocalizedString(
            "refundAPIError.invalidRefundAmount",
            value: "The refund amount isn't valid.",
            comment: "Error shown when a refund is rejected because the refund amount is not valid."
        )
    }
}
