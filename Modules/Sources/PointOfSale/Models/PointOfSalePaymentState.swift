import Foundation

struct PointOfSalePaymentState: Equatable {
    var card: PointOfSaleCardPaymentState
    var cash: PointOfSaleCashPaymentState

    init(card: PointOfSaleCardPaymentState, cash: PointOfSaleCashPaymentState) {
        self.card = card
        self.cash = cash
    }

    static var idle: PointOfSalePaymentState {
        .init(card: .idle, cash: .idle)
    }

    var activePaymentMethod: PointOfSalePaymentMethod {
        if cash != .idle {
            return .cash
        }
        return .card
    }

    var shownFullScreen: Bool {
        switch activePaymentMethod {
        case .cash:
            return cash.shownFullScreen
        case .card:
            return card.shownFullScreen
        }
    }

    var isSuccess: Bool {
        switch (card, cash) {
        case (.cardPaymentSuccessful, _):
            return true
        case (_, .paymentSuccess):
            return true
        default:
            return false
        }
    }

    var allowsCashPayment: Bool {
        switch card {
        case .idle, .validatingOrderError, .paymentIntentCreationError, .acceptingCard:
            return true
        case .validatingOrder, .preparingReader, .cardInserted, .processingPayment,
             .paymentError, .cardPaymentSuccessful:
            return false
        }
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
