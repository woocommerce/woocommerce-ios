import Foundation
import Testing
import enum NetworkingCore.DotcomError
import enum NetworkingCore.NetworkError
@testable import Yosemite

/// Covers the mapping from refund endpoint rejection codes to `RefundAPIError`.
///
struct RefundAPIErrorTests {

    @Test func init_maps_each_actionable_code_from_dotcom_unknown_error() {
        // Given the unprefixed codes the refund endpoints return with 400/422 statuses
        let expectations: [(code: String, rejection: RefundAPIError)] = [
            ("quantity_exceeds_refundable", .quantityExceedsRefundable),
            ("line_item_already_refunded", .lineItemAlreadyRefunded),
            ("order_not_refundable", .orderNotRefundable),
            ("preview_exceeds_max_refundable", .refundExceedsRemaining),
            ("refund_exceeds_remaining", .refundExceedsRemaining),
            ("refund_total_exceeds_line", .refundTotalExceedsLine),
            ("invalid_refund_amount", .invalidRefundAmount)
        ]

        for (code, rejection) in expectations {
            // When
            let mapped = RefundAPIError(DotcomError.unknown(code: code, message: nil, data: nil))

            // Then
            #expect(mapped == rejection, "Expected \(code) to map to \(rejection)")
        }
    }

    @Test func init_maps_code_from_network_error_response_body() {
        // Given a REST 422 whose body carries the rejection code
        let response = Data(#"{"code":"refund_exceeds_remaining"}"#.utf8)
        let error = NetworkError.unacceptableStatusCode(statusCode: 422, response: response)

        // When
        let mapped = RefundAPIError(error)

        // Then
        #expect(mapped == .refundExceedsRemaining)
    }

    @Test func init_returns_nil_for_programming_error_codes() {
        // Given codes that indicate a client bug rather than an actionable order state change
        let programmingErrorCodes = [
            "invalid_line_item",
            "invalid_quantity",
            "invalid_refund_total",
            "missing_quantity_or_refund_total",
            "duplicate_line_item",
            "line_item_not_found",
            "missing_line_items"
        ]

        for code in programmingErrorCodes {
            // When / Then the generic error path is kept
            #expect(RefundAPIError(DotcomError.unknown(code: code, message: nil, data: nil)) == nil,
                    "Expected \(code) to stay unmapped")
        }
    }

    @Test func init_returns_nil_for_rest_no_route_so_availability_fallback_is_preserved() {
        // Given the two shapes the missing-route failure arrives in
        let dotcomError = DotcomError.noRestRoute()
        let networkError = NetworkError.notFound(response: Data(#"{"code":"rest_no_route"}"#.utf8))

        // When / Then
        #expect(RefundAPIError(dotcomError) == nil)
        #expect(RefundAPIError(networkError) == nil)
    }

    @Test func init_returns_nil_for_unrelated_errors() {
        // When / Then
        #expect(RefundAPIError(NSError(domain: "test", code: 1)) == nil)
        #expect(RefundAPIError(NetworkError.timeout()) == nil)
    }

    @Test func errorDescription_is_non_empty_for_every_rejection() {
        // Given
        let rejections: [RefundAPIError] = [
            .quantityExceedsRefundable,
            .lineItemAlreadyRefunded,
            .orderNotRefundable,
            .refundExceedsRemaining,
            .refundTotalExceedsLine,
            .invalidRefundAmount
        ]

        for rejection in rejections {
            // When / Then
            #expect(rejection.errorDescription?.isEmpty == false)
        }
    }
}
