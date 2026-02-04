// POSBookingListStateTests.swift
import Foundation
import Testing
@testable import PointOfSale

struct POSBookingListStateTests {
    @Test func isLoading_true_only_for_loading_state() {
        #expect(POSBookingListState.loading.isLoading == true)
        #expect(POSBookingListState.loaded([]).isLoading == false)
        #expect(POSBookingListState.empty.isLoading == false)
        #expect(POSBookingListState.error(.errorOnLoadingBookings()).isLoading == false)
    }

    @Test func bookings_returns_array_for_loaded_state() {
        let bookings = [POSBookingTests.makeBooking()]
        let state = POSBookingListState.loaded(bookings)

        #expect(state.bookings == bookings)
    }

    @Test func bookings_returns_empty_for_other_states() {
        #expect(POSBookingListState.loading.bookings.isEmpty)
        #expect(POSBookingListState.empty.bookings.isEmpty)
        #expect(POSBookingListState.error(.errorOnLoadingBookings()).bookings.isEmpty)
    }
}
