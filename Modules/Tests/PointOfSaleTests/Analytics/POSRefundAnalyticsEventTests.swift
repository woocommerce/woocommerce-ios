import Testing
import Foundation
import enum NetworkingCore.DotcomError
import struct WooFoundation.WooAnalyticsEvent
@testable import PointOfSale

/// Covers the properties the refund processing events carry: the calculation flow on all three,
/// and the REST rejection code on the failure event.
struct POSRefundAnalyticsEventTests {

    @Test func refundProcessingStarted_reports_the_calculation_flow() {
        // Given / When
        let event = WooAnalyticsEvent.PointOfSale.refundProcessingStarted(flow: .serverComputed)

        // Then
        #expect(event.properties["refund_flow"] as? String == "server_computed")
    }

    @Test func refundProcessingSuccess_reports_the_calculation_flow() {
        // Given / When
        let event = WooAnalyticsEvent.PointOfSale.refundProcessingSuccess(flow: .local)

        // Then
        #expect(event.properties["refund_flow"] as? String == "local")
    }

    @Test func refundProcessingFailed_reports_the_rest_rejection_code() {
        // Given
        let rejection = DotcomError.unknown(code: "woocommerce_rest_refund_exceeds_remaining", message: nil, data: nil)

        // When
        let event = WooAnalyticsEvent.PointOfSale.refundProcessingFailed(error: rejection, flow: .serverComputed)

        // Then
        #expect(event.properties["api_error_code"] as? String == "woocommerce_rest_refund_exceeds_remaining")
        #expect(event.properties["refund_flow"] as? String == "server_computed")
    }

    @Test func refundProcessingFailed_when_the_error_carries_no_code_then_omits_the_property() {
        // Given
        let transportFailure = NSError(domain: "test", code: 1)

        // When
        let event = WooAnalyticsEvent.PointOfSale.refundProcessingFailed(error: transportFailure, flow: .local)

        // Then the property is omitted rather than sent empty
        #expect(event.properties["api_error_code"] == nil)
        #expect(event.properties["refund_flow"] as? String == "local")
    }
}
