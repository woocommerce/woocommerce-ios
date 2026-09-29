import Testing
import enum Yosemite.RefundAPIError
@testable import PointOfSale

struct POSRefundRecoveryTests {
    @Test func refund_rejections_a_reload_can_fix_offer_the_item_refresh() {
        let expected: [(RefundAPIError, POSRefundRecovery)] = [
            (.quantityExceedsRefundable, .refreshItems),
            (.lineItemAlreadyRefunded, .refreshItems),
            (.refundExceedsRemaining, .refreshItems),
            (.refundTotalExceedsLine, .refreshItems),
            (.orderNotRefundable, .dismiss),
            (.invalidRefundAmount, .dismiss)
        ]

        for (rejection, recovery) in expected {
            #expect(rejection.recovery == recovery, "recovery for \(rejection)")
        }
    }

    @Test func no_refund_rejection_offers_a_retry() {
        // Every mapped code is a deterministic validation rejection: the same request always gets
        // the same answer, so a retry cannot be the way out.
        let rejections: [RefundAPIError] = [
            .quantityExceedsRefundable,
            .lineItemAlreadyRefunded,
            .orderNotRefundable,
            .refundExceedsRemaining,
            .refundTotalExceedsLine,
            .invalidRefundAmount
        ]

        #expect(rejections.allSatisfy { $0.recovery != .retry })
    }
}
