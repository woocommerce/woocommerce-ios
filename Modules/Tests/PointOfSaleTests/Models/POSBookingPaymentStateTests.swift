// POSBookingPaymentStateTests.swift
import Testing
@testable import PointOfSale

struct POSBookingPaymentStateTests {
    @Test func canCancel_true_for_ready_and_error_states() {
        #expect(POSBookingPaymentState.ready.canCancel == true)
        #expect(POSBookingPaymentState.error("Failed").canCancel == true)
        #expect(POSBookingPaymentState.processing.canCancel == false)
        #expect(POSBookingPaymentState.success.canCancel == false)
    }

    @Test func showsAmount_true_for_ready_and_processing() {
        #expect(POSBookingPaymentState.ready.showsAmount == true)
        #expect(POSBookingPaymentState.processing.showsAmount == true)
        #expect(POSBookingPaymentState.success.showsAmount == true)
        #expect(POSBookingPaymentState.error("Failed").showsAmount == false)
    }

    @Test func errorMessage_returns_message_for_error_state() {
        let state = POSBookingPaymentState.error("Card declined")
        #expect(state.errorMessage == "Card declined")
    }

    @Test func errorMessage_returns_nil_for_non_error_states() {
        #expect(POSBookingPaymentState.ready.errorMessage == nil)
        #expect(POSBookingPaymentState.processing.errorMessage == nil)
        #expect(POSBookingPaymentState.success.errorMessage == nil)
    }
}
