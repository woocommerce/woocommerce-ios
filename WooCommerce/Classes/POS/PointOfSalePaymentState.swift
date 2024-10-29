enum PointOfSalePaymentState {
    case idle
    case acceptingCard
    case validatingOrder
    case validatingOrderError
    case preparingReader
    case processingPayment
    case paymentError
    case cardPaymentSuccessful
}

extension PointOfSalePaymentState {
    init?(from cardPaymentEvent: CardPresentPaymentEvent) {
        let emptyDependencies = PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies(
            tryPaymentAgainBackToCheckoutAction: {},
            nonRetryableErrorExitAction: {},
            formattedOrderTotalPrice: "",
            paymentCaptureErrorTryAgainAction: {},
            paymentCaptureErrorNewOrderAction: {},
            paymentIntentCreationErrorEditOrderAction: {},
            dismissReaderConnectionModal: {})

        switch cardPaymentEvent {
        case .idle:
            self = .idle
        case .show(.validatingOrder):
            self = .validatingOrder
        case .show(.preparingForPayment):
            self = .preparingReader
        case .show(.tapSwipeOrInsertCard):
            self = .acceptingCard
        case .show(.processing),
                .show(.displayReaderMessage):
            self = .processingPayment
        case .show(.paymentError):
            if case let .show(eventDetails) = cardPaymentEvent,
               case let .message(messageType) = PointOfSaleCardPresentPaymentEventPresentationStyle(
                for: eventDetails,
                dependencies: emptyDependencies),
               case .validatingOrderError = messageType {
                self = .validatingOrderError
            } else {
                self = .paymentError
            }
        case .show(.paymentCaptureError):
            self = .paymentError
        case .show(.paymentSuccess):
            self = .cardPaymentSuccessful
        default:
            return nil
        }
    }
}
