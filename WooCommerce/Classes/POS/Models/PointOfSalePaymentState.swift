import Foundation

struct PointOfSalePaymentState: Equatable {
    var card: PointOfSaleCardPaymentState
    var cash: PointOfSaleCashPaymentState

    init(card: PointOfSaleCardPaymentState = .idle, cash: PointOfSaleCashPaymentState = .idle) {
        self.card = card
        self.cash = cash
    }

    var shownFullScreen: Bool {
        if cash != .idle {
            return cash.shownFullScreen
        }

        return card.shownFullScreen
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
