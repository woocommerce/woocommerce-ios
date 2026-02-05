// POSBookingPaymentController.swift
import Foundation
import Observation
import Combine
import Yosemite
import Networking

public protocol POSOrderProviding {
    func fetchOrder(siteID: Int64, orderID: Int64) async throws -> Order
}

@MainActor
@Observable
final class POSBookingPaymentController {
    private(set) var paymentState: POSBookingPaymentState = .ready

    let booking: POSBooking

    private let siteID: Int64
    private let bookingService: POSBookingServiceProtocol
    private let cardPaymentFacade: CardPresentPaymentFacade
    private let orderProvider: POSOrderProviding
    private var cancellables = Set<AnyCancellable>()

    init(
        siteID: Int64,
        booking: POSBooking,
        bookingService: POSBookingServiceProtocol,
        cardPaymentFacade: CardPresentPaymentFacade,
        orderProvider: POSOrderProviding
    ) {
        self.siteID = siteID
        self.booking = booking
        self.bookingService = bookingService
        self.cardPaymentFacade = cardPaymentFacade
        self.orderProvider = orderProvider
    }

    func collectCardPayment() async throws {
        guard let orderID = booking.orderID else {
            paymentState = .error(Localization.noOrderError)
            throw BookingPaymentError.noLinkedOrder
        }

        paymentState = .processing

        do {
            let order = try await orderProvider.fetchOrder(siteID: siteID, orderID: orderID)
            let result = try await cardPaymentFacade.collectPayment(
                for: order,
                using: .bluetooth,
                channel: .pos
            )

            switch result {
            case .success:
                try? await bookingService.markBookingAsPaid(siteID: siteID, bookingID: booking.bookingID)
                paymentState = .success
            case .cancellation:
                paymentState = .ready
            }
        } catch {
            paymentState = .error(error.localizedDescription)
            throw error
        }
    }

    func cancelPayment() async throws {
        try await cardPaymentFacade.cancelPayment()
        paymentState = .ready
    }

    func reset() {
        paymentState = .ready
    }

    private enum Localization {
        static let noOrderError = NSLocalizedString(
            "posBookingPaymentController.noOrderError",
            value: "This booking has no linked order",
            comment: "Error when trying to pay for a booking without a linked order"
        )
    }
}

enum BookingPaymentError: Error {
    case noLinkedOrder
}