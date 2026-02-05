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
final class POSBookingPaymentController: Identifiable, Equatable {
    nonisolated let id = UUID()

    nonisolated static func == (lhs: POSBookingPaymentController, rhs: POSBookingPaymentController) -> Bool {
        lhs.id == rhs.id
    }
    private(set) var paymentState: POSBookingPaymentState = .ready

    // Must be `var` (not private(set)) to allow binding from view's posModal
    var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    private(set) var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected

    /// Whether the view should show a primary (purple) background - only during actual payment processing
    var showsPrimaryBackground: Bool {
        guard let message = cardPresentPaymentInlineMessage else {
            return false
        }
        switch message {
        case .processing, .displayReaderMessage:
            return true
        default:
            return false
        }
    }

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
        setupSubscriptions()
    }

    func collectCardPayment() async throws {
        guard let orderID = booking.orderID else {
            paymentState = .error(Localization.noOrderError)
            throw BookingPaymentError.noLinkedOrder
        }

        // Check if reader is connected
        switch cardReaderConnectionStatus {
        case .connected:
            try await collectCardPaymentInternal(orderID: orderID)
        case .disconnected, .cancellingConnection, .disconnecting:
            // Start connection flow
            let connectionResult = try await cardPaymentFacade.connectReader(using: .bluetooth)
            switch connectionResult {
            case .connected:
                // Reader connected, proceed to payment
                try await collectCardPaymentInternal(orderID: orderID)
            case .canceled:
                // User cancelled connection
                paymentState = .ready
            }
        }
    }

    private func collectCardPaymentInternal(orderID: Int64) async throws {
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
                cardPresentPaymentInlineMessage = nil
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

    func cancelPendingOperations() {
        cardPaymentFacade.cancelPayment()
    }

    // MARK: - Subscriptions

    private func setupSubscriptions() {
        publishCardReaderConnectionStatus()
        publishPaymentMessages()
    }

    private func publishCardReaderConnectionStatus() {
        cardPaymentFacade.readerConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connectionStatus in
                self?.cardReaderConnectionStatus = connectionStatus
            }
            .store(in: &cancellables)
    }

    private func publishPaymentMessages() {
        cardPaymentFacade.paymentEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handlePaymentEvent(event)
            }
            .store(in: &cancellables)
    }

    private func handlePaymentEvent(_ event: CardPresentPaymentEvent) {
        switch event {
        case .idle:
            cardPresentPaymentAlertViewModel = nil
            cardPresentPaymentInlineMessage = nil
        case .show(let eventDetails):
            let dependencies = makePresentationDependencies()
            // Failable initializer - returns nil for unsupported events
            guard let style = PointOfSaleCardPresentPaymentEventPresentationStyle(
                for: eventDetails,
                dependencies: dependencies
            ) else {
                return
            }
            switch style {
            case .alert(let alertType):
                cardPresentPaymentAlertViewModel = alertType
                cardPresentPaymentInlineMessage = nil
            case .message(let messageType):
                // Skip paymentSuccess - our view has its own success UI with appropriate buttons
                if case .paymentSuccess = messageType {
                    cardPresentPaymentInlineMessage = nil
                    // Transition to success immediately to avoid showing processingContent on light background
                    paymentState = .success
                } else {
                    cardPresentPaymentAlertViewModel = nil
                    cardPresentPaymentInlineMessage = messageType
                }
            }
        case .showOnboarding:
            // Onboarding not supported for bookings yet
            break
        }
    }

    private func makePresentationDependencies() -> PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies {
        PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies(
            tryPaymentAgainBackToCheckoutAction: { [weak self] in
                self?.paymentState = .ready
                self?.cardPresentPaymentAlertViewModel = nil
                self?.cardPresentPaymentInlineMessage = nil
            },
            nonRetryableErrorExitAction: { [weak self] in
                self?.paymentState = .ready
                self?.cardPresentPaymentAlertViewModel = nil
            },
            formattedOrderTotalPrice: booking.amount,
            paymentCaptureErrorTryAgainAction: { [weak self] in
                Task { try? await self?.collectCardPayment() }
            },
            paymentCaptureErrorNewOrderAction: { [weak self] in
                self?.paymentState = .ready
            },
            paymentIntentCreationErrorEditOrderAction: { [weak self] in
                self?.paymentState = .ready
            },
            dismissReaderConnectionModal: { [weak self] in
                self?.cardPresentPaymentAlertViewModel = nil
            }
        )
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