import Foundation

enum PointOfSalePaymentState: Equatable {
    case card(PointOfSaleCardPaymentState)
    case cash(PointOfSaleCashPaymentState)
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
    case collectingCash
    case paymentSuccess
}

extension PointOfSalePaymentState {
    init?(from cardPaymentEvent: CardPresentPaymentEvent,
          using paymentEventPresentationStyleDependencies: PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies) {
        switch cardPaymentEvent {
        case .idle:
            self = .card(.idle)
        case .show(.validatingOrder):
            self = .card(.validatingOrder)
        case .show(.preparingForPayment):
            self = .card(.preparingReader)
        case .show(.tapSwipeOrInsertCard):
            self = .card(.acceptingCard)
        case .show(.cardInserted):
            self = .card(.cardInserted)
        case .show(.processing),
                .show(.displayReaderMessage):
            self = .card(.processingPayment)
        case .show(.paymentError):
            if case let .show(eventDetails) = cardPaymentEvent,
               case let .message(messageType) = PointOfSaleCardPresentPaymentEventPresentationStyle(
                for: eventDetails,
                dependencies: paymentEventPresentationStyleDependencies),
               case .validatingOrderError = messageType {
                self = .card(.validatingOrderError)
            } else {
                self = .card(.paymentError)
            }
        case .show(.paymentCaptureError):
            self = .card(.paymentError)
        case .show(.paymentSuccess):
            self = .card(.cardPaymentSuccessful)
        case .show(.paymentIntentCreationError):
            self = .card(.paymentIntentCreationError)
        default:
            return nil
        }
    }

    var shownFullScreen: Bool {
        switch self {
        case .card(.processingPayment),
                .card(.paymentError),
                .card(.cardPaymentSuccessful):
            return true
        case .card(.idle),
                .card(.validatingOrder),
                .card(.validatingOrderError),
                .card(.paymentIntentCreationError),
                .card(.preparingReader),
                .card(.acceptingCard),
                .card(.cardInserted):
            return false
        case .cash:
            return true
        }
    }
}
