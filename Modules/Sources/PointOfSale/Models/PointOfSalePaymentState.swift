import Foundation

struct PointOfSalePaymentState: Equatable {
    var card: PointOfSaleCardPaymentState
    var cash: PointOfSaleCashPaymentState
    var scanToPay: PointOfSaleScanToPayState
    var markAsPaid: PointOfSaleMarkAsPaidState

    init(card: PointOfSaleCardPaymentState,
         cash: PointOfSaleCashPaymentState,
         scanToPay: PointOfSaleScanToPayState = .idle,
         markAsPaid: PointOfSaleMarkAsPaidState = .idle) {
        self.card = card
        self.cash = cash
        self.scanToPay = scanToPay
        self.markAsPaid = markAsPaid
    }

    static var idle: PointOfSalePaymentState {
        .init(card: .idle, cash: .idle, scanToPay: .idle, markAsPaid: .idle)
    }

    var activePaymentMethod: PointOfSalePaymentMethod {
        if cash != .idle {
            return .cash
        }
        if scanToPay != .idle {
            return .scanToPay
        }
        if markAsPaid != .idle {
            return .markAsPaid
        }
        return .card
    }

    var shownFullScreen: Bool {
        switch activePaymentMethod {
        case .cash:
            return cash.shownFullScreen
        case .scanToPay:
            return scanToPay.shownFullScreen
        case .markAsPaid:
            return markAsPaid.shownFullScreen
        case .card:
            return card.shownFullScreen
        }
    }

    var isSuccess: Bool {
        if case .cardPaymentSuccessful = card { return true }
        if cash == .paymentSuccess { return true }
        if case .paymentSuccess = scanToPay { return true }
        if markAsPaid == .paymentSuccess { return true }
        return false
    }

    /// Whether secondary payment methods (cash / scan-to-pay / mark-as-paid) can take over
    /// the in-flight card flow without yanking the rug out of an active reader transaction.
    var allowsSecondaryPaymentMethod: Bool {
        switch card {
        case .idle, .validatingOrderError, .paymentIntentCreationError, .acceptingCard:
            return true
        case .validatingOrder, .preparingReader, .cardInserted, .processingPayment,
             .paymentError, .cardPaymentSuccessful:
            return false
        }
    }

    var allowsCashPayment: Bool {
        guard scanToPay == .idle, markAsPaid == .idle else { return false }
        return allowsSecondaryPaymentMethod
    }

    var allowsScanToPayPayment: Bool {
        guard cash == .idle, markAsPaid == .idle else { return false }
        return allowsSecondaryPaymentMethod
    }

    var allowsMarkAsPaidPayment: Bool {
        guard cash == .idle, scanToPay == .idle else { return false }
        return allowsSecondaryPaymentMethod
    }
}

enum PointOfSaleCardPaymentState: Equatable {
    case idle
    case acceptingCard
    case cardInserted
    case validatingOrder
    case validatingOrderError
    case paymentIntentCreationError
    case preparingReader
    case processingPayment
    case paymentError
    case cardPaymentSuccessful
}

enum PointOfSaleCashPaymentState: Equatable {
    case idle
    case collectingCash
    case paymentSuccess
}

enum PointOfSaleScanToPayState: Equatable {
    case idle
    /// QR is on screen and we're polling the order to detect when the customer pays.
    /// `verification` reflects the polling state; `.confirming` is shown once a paid
    /// status is detected and we're transitioning to success.
    case showingQRCode(verification: ScanToPayVerificationStatus)
    case paymentSuccess
}

/// Tracks scan-to-pay polling state independently of the high-level state.
enum ScanToPayVerificationStatus: Equatable {
    /// Polling is in progress.
    case waiting
    /// A polling cycle errored out — we keep showing the QR but display a warning.
    case error
    /// Backend confirmed the payment; transitioning to success momentarily.
    case confirming
}

enum PointOfSaleMarkAsPaidState: Equatable {
    case idle
    /// Confirmation alert is shown to the merchant.
    case confirming
    /// Network call in flight.
    case processing
    case paymentSuccess
}

extension PointOfSaleCardPaymentState {
    init?(from cardPaymentEvent: CardPresentPaymentEvent,
          using paymentEventPresentationStyleDependencies: PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies) {
        switch cardPaymentEvent {
        case .idle:
            self = .idle
        case .show(.validatingOrder):
            self = .validatingOrder
        case .show(.preparingForPayment):
            self = .preparingReader
        case .show(.tapSwipeOrInsertCard):
            self = .acceptingCard
        case .show(.cardInserted):
            self = .cardInserted
        case .show(.processing),
                .show(.displayReaderMessage):
            self = .processingPayment
        case .show(.paymentError):
            if case let .show(eventDetails) = cardPaymentEvent,
               case let .message(messageType) = PointOfSaleCardPresentPaymentEventPresentationStyle(
                for: eventDetails,
                dependencies: paymentEventPresentationStyleDependencies),
               case .validatingOrderError = messageType {
                self = .validatingOrderError
            } else {
                self = .paymentError
            }
        case .show(.paymentCaptureError):
            self = .paymentError
        case .show(.paymentSuccess):
            self = .cardPaymentSuccessful
        case .show(.paymentIntentCreationError):
            self = .paymentIntentCreationError
        default:
            return nil
        }
    }

    var shownFullScreen: Bool {
        switch self {
        case .processingPayment,
                .paymentError,
                .cardPaymentSuccessful:
            return true
        case .idle,
                .validatingOrder,
                .validatingOrderError,
                .paymentIntentCreationError,
                .preparingReader,
                .acceptingCard,
                .cardInserted:
            return false
        }
    }

    var requiresCashExit: Bool {
        switch self {
        case .cardInserted, .processingPayment, .cardPaymentSuccessful:
            return true
        case .idle, .validatingOrder, .validatingOrderError, .paymentIntentCreationError,
             .preparingReader, .acceptingCard, .paymentError:
            return false
        }
    }

    var resetsToIdleOnDisconnect: Bool {
        switch self {
        case .preparingReader, .acceptingCard, .validatingOrder:
            return true
        case .idle, .validatingOrderError, .paymentIntentCreationError,
             .cardInserted, .processingPayment, .paymentError, .cardPaymentSuccessful:
            return false
        }
    }
}

extension PointOfSaleCashPaymentState {
    var shownFullScreen: Bool {
        switch self {
        case .idle:
            return false
        case .collectingCash, .paymentSuccess:
            return true
        }
    }
}

extension PointOfSaleScanToPayState {
    var shownFullScreen: Bool {
        switch self {
        case .idle:
            return false
        case .showingQRCode, .paymentSuccess:
            return true
        }
    }

    /// Convenience: are we currently presenting the QR code (regardless of verification status).
    var isShowingQRCode: Bool {
        if case .showingQRCode = self { return true }
        return false
    }
}

extension PointOfSaleMarkAsPaidState {
    /// The merchant-confirming and processing states stay inline (alert / spinner over the
    /// existing UI). Only `.paymentSuccess` takes over full-screen.
    var shownFullScreen: Bool {
        switch self {
        case .idle, .confirming, .processing:
            return false
        case .paymentSuccess:
            return true
        }
    }
}
