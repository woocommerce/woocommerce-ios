import Foundation

struct PointOfSalePaymentState: Equatable {
    var card: PointOfSaleCardPaymentState
    var cash: PointOfSaleCashPaymentState
    var markAsPaid: PointOfSaleMarkAsPaidState

    init(card: PointOfSaleCardPaymentState,
         cash: PointOfSaleCashPaymentState,
         markAsPaid: PointOfSaleMarkAsPaidState = .idle) {
        self.card = card
        self.cash = cash
        self.markAsPaid = markAsPaid
    }

    static var idle: PointOfSalePaymentState {
        .init(card: .idle, cash: .idle, markAsPaid: .idle)
    }

    var activePaymentMethod: PointOfSalePaymentMethod {
        if cash != .idle {
            return .cash
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
        case .markAsPaid:
            return markAsPaid.shownFullScreen
        case .card:
            return card.shownFullScreen
        }
    }

    var isSuccess: Bool {
        if case .cardPaymentSuccessful = card { return true }
        if cash == .paymentSuccess { return true }
        if markAsPaid == .paymentSuccess { return true }
        return false
    }

    /// Whether secondary payment methods can take over the in-flight card flow without
    /// yanking the rug out of an active reader transaction. Shared between cash and
    /// mark-as-paid so any future secondary method can plug in here.
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
        guard markAsPaid == .idle else { return false }
        return allowsSecondaryPaymentMethod
    }

    var allowsMarkAsPaidPayment: Bool {
        guard cash == .idle else { return false }
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

/// Stages of the manual "mark as paid" flow. The `confirming` and `processing` stages stay
/// inline (alert + spinner over the existing UI); only `paymentSuccess` takes over full-screen.
enum PointOfSaleMarkAsPaidState: Equatable {
    case idle
    /// Confirmation alert is shown to the merchant.
    case confirming
    /// Network call in flight (status update sent, awaiting response).
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

extension PointOfSaleMarkAsPaidState {
    /// Confirmation alert and processing spinner stay inline (modal over the totals view);
    /// only `paymentSuccess` takes over full-screen.
    var shownFullScreen: Bool {
        switch self {
        case .idle, .confirming, .processing:
            return false
        case .paymentSuccess:
            return true
        }
    }
}
