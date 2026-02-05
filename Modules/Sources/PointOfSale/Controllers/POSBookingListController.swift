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
    private(set) var isRefreshing: Bool = false

    private let siteID: Int64
    private let bookingService: POSBookingServiceProtocol
    private let currencyFormatter: CurrencyFormatter
    private var resources: [Int64: BookingResource] = [:]

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
            let result = try await bookingService.fetchTodaysBookings(siteID: siteID)
            resources = result.resources
            if result.bookings.isEmpty {
                state = .empty
            } else {
                let posBookings = result.bookings.map { mapToPOSBooking($0) }
                    .sorted { $0.startTime < $1.startTime }
                state = .loaded(posBookings)
            }
        } catch {
            state = .error(.errorOnLoadingBookings(error: error))
        }
    }

    /// Refreshes bookings while keeping existing content visible.
    /// Updates the selected booking with fresh data after refresh.
    func refreshBookings() async {
        // Keep existing content and show refreshing indicator
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let result = try await bookingService.fetchTodaysBookings(siteID: siteID)
            resources = result.resources

            if result.bookings.isEmpty {
                state = .empty
                selectedBooking = nil
            } else {
                let posBookings = result.bookings.map { mapToPOSBooking($0) }
                    .sorted { $0.startTime < $1.startTime }
                state = .loaded(posBookings)

                // Update selected booking with fresh data
                if let currentSelection = selectedBooking,
                   let updatedBooking = posBookings.first(where: { $0.bookingID == currentSelection.bookingID }) {
                    selectedBooking = updatedBooking
                }
            }
        } catch {
            // On refresh error, keep existing content but log error
            // Don't replace state with error to avoid losing visible bookings
        }
    }

    func selectBooking(_ booking: POSBooking?) {
        selectedBooking = booking
    }

    func clearSelection() {
        selectedBooking = nil
    }

    private func mapToPOSBooking(_ booking: Booking) -> POSBooking {
        let isPaid = booking.statusKey == "paid" || booking.statusKey == "complete"
        let isCancelled = booking.statusKey == "cancelled"

        // Format amounts
        let paymentInfo = booking.orderInfo?.paymentInfo
        let amount = currencyFormatter.formatAmount(Decimal(string: paymentInfo?.total ?? booking.cost) ?? 0)
            ?? paymentInfo?.total ?? booking.cost
        let subtotal = paymentInfo.flatMap { currencyFormatter.formatAmount(Decimal(string: $0.subtotal) ?? 0) }
        let tax = paymentInfo.flatMap { currencyFormatter.formatAmount(Decimal(string: $0.totalTax) ?? 0) }

        // Get customer info
        let customerInfo = booking.orderInfo?.customerInfo
        let billingAddress = customerInfo?.billingAddress
        let customerName = formatCustomerName(billingAddress: billingAddress)
        let customerEmail = billingAddress?.email
        let customerPhone = billingAddress?.phone

        // Get resource name
        let resourceName = resources[booking.resourceID]?.name

        // Map attendance status
        let attendanceStatus = mapAttendanceStatus(booking.attendanceStatus)

        return POSBooking(
            bookingID: booking.bookingID,
            orderID: booking.orderID > 0 ? booking.orderID : nil,
            customerName: customerName,
            serviceName: booking.orderInfo?.productInfo?.name ?? Localization.booking,
            startTime: booking.startDate,
            endTime: booking.endDate,
            amount: amount,
            isPaid: isPaid,
            isCancelled: isCancelled,
            resourceName: resourceName,
            customerEmail: customerEmail,
            customerPhone: customerPhone,
            subtotal: subtotal,
            tax: tax,
            attendanceStatus: attendanceStatus
        )
    }

    private func formatCustomerName(billingAddress: Address?) -> String {
        guard let address = billingAddress else {
            return Localization.guest
        }
        let firstName = address.firstName.trimmingCharacters(in: .whitespaces)
        let lastName = address.lastName.trimmingCharacters(in: .whitespaces)

        if firstName.isEmpty && lastName.isEmpty {
            return Localization.guest
        }
        return [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    private func mapAttendanceStatus(_ status: BookingAttendanceStatus) -> POSBookingAttendanceStatus {
        switch status {
        case .booked:
            return .booked
        case .checkedIn:
            return .checkedIn
        case .cancelled:
            return .cancelled
        case .noShow:
            return .noShow
        case .unknown:
            return .unknown
        }
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
