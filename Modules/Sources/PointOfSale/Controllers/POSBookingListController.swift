// POSBookingListController.swift
import Foundation
import Observation
import Yosemite
import Networking
import class WooFoundation.CurrencyFormatter

@MainActor
@Observable
final class POSBookingListController {
    private(set) var state: POSBookingListState = .loading
    private(set) var selectedBooking: POSBooking?

    private let siteID: Int64
    private let bookingService: POSBookingServiceProtocol
    private let currencyFormatter: CurrencyFormatter

    init(
        siteID: Int64,
        bookingService: POSBookingServiceProtocol,
        currencyFormatter: CurrencyFormatter
    ) {
        self.siteID = siteID
        self.bookingService = bookingService
        self.currencyFormatter = currencyFormatter
    }

    func loadBookings() async {
        state = .loading
        do {
            let bookings = try await bookingService.fetchTodaysBookings(siteID: siteID)
            if bookings.isEmpty {
                state = .empty
            } else {
                let posBookings = bookings.map { mapToPOSBooking($0) }
                    .sorted { $0.startTime < $1.startTime }
                state = .loaded(posBookings)
            }
        } catch {
            state = .error(.errorOnLoadingBookings(error: error))
        }
    }

    func refreshBookings() async {
        await loadBookings()
    }

    func selectBooking(_ booking: POSBooking?) {
        selectedBooking = booking
    }

    func clearSelection() {
        selectedBooking = nil
    }

    private func mapToPOSBooking(_ booking: Booking) -> POSBooking {
        let amount = currencyFormatter.formatAmount(Decimal(string: booking.cost) ?? 0) ?? booking.cost
        let isPaid = booking.statusKey == "paid" || booking.statusKey == "complete"
        let isCancelled = booking.statusKey == "cancelled"

        return POSBooking(
            bookingID: booking.bookingID,
            orderID: booking.orderID > 0 ? booking.orderID : nil,
            customerName: booking.orderInfo?.customerInfo?.billingAddress.firstName ?? Localization.guest,
            serviceName: booking.orderInfo?.productInfo?.name ?? Localization.booking,
            startTime: booking.startDate,
            amount: amount,
            isPaid: isPaid,
            isCancelled: isCancelled
        )
    }

    private enum Localization {
        static let guest = NSLocalizedString(
            "posBookingListController.guest",
            value: "Guest",
            comment: "Placeholder for booking without customer name"
        )
        static let booking = NSLocalizedString(
            "posBookingListController.booking",
            value: "Booking",
            comment: "Placeholder for booking without service name"
        )
    }
}
