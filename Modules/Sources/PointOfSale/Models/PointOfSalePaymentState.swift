import Foundation

struct PointOfSalePaymentState: Equatable {
    var card: PointOfSaleCardPaymentState
    var cash: PointOfSaleCashPaymentState
    var scanToPay: PointOfSaleScanToPayState

    init(card: PointOfSaleCardPaymentState,
         cash: PointOfSaleCashPaymentState,
         scanToPay: PointOfSaleScanToPayState = .idle) {
        self.card = card
        self.cash = cash
        self.scanToPay = scanToPay
    }

    static var idle: PointOfSalePaymentState {
        .init(card: .idle, cash: .idle, scanToPay: .idle)
    }

    var activePaymentMethod: PointOfSalePaymentMethod {
        if cash != .idle {
            return .cash
        }
        if scanToPay != .idle {
            return .scanToPay
        }
        return .card
    }

    var shownFullScreen: Bool {
        switch activePaymentMethod {
        case .cash:
            return cash.shownFullScreen
        case .scanToPay:
            return scanToPay.shownFullScreen
        case .card:
            return card.shownFullScreen
        }
    }

    var isSuccess: Bool {
        switch (card, cash, scanToPay) {
        case (.cardPaymentSuccessful, _, _):
            return true
        case (_, .paymentSuccess, _):
            return true
        case (_, _, .paymentSuccess):
            return true
        default:
            return false
        }
    }

    var allowsCashPayment: Bool {
        guard scanToPay == .idle else { return false }
        switch card {
        case .idle, .validatingOrderError, .paymentIntentCreationError, .acceptingCard:
            return true
        case .validatingOrder, .preparingReader, .cardInserted, .processingPayment,
             .paymentError, .cardPaymentSuccessful:
            return false
        }
    }

    var allowsScanToPayPayment: Bool {
        guard cash == .idle else { return false }
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

enum PointOfSaleScanToPayState: Equatable {
    case idle
    case showingQRCode
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
}
