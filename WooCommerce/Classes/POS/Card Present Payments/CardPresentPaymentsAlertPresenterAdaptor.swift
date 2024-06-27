import Foundation
import Combine

final class CardPresentPaymentsAlertPresenterAdaptor: CardPresentPaymentAlertsPresenting {
    typealias AlertDetails = CardPresentPaymentEventDetails
    let paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never>

    private let paymentEventSubject: PassthroughSubject<CardPresentPaymentEvent, Never> = PassthroughSubject()

    private var latestReaderConnectionHandler: ((String?) -> Void)?

    init() {
        paymentEventPublisher = paymentEventSubject.eraseToAnyPublisher()
    }

    func present(viewModel eventDetails: CardPresentPaymentEventDetails) {
        switch eventDetails {
        case .paymentError(let error, let tryAgain, let cancelPayment):
            paymentEventSubject.send(.show(
                eventDetails: .paymentError(
                    error: error,
                    tryAgain: tryAgain,
                    cancelPayment: { [weak self] in
                        // TODO: this should also call CardPresentPaymentFacade.cancelPayment
                        cancelPayment()
                        self?.paymentEventSubject.send(.idle)
                    })))
        case .paymentErrorNonRetryable(let error, let cancelPayment):
            paymentEventSubject.send(.show(
                eventDetails: .paymentErrorNonRetryable(
                    error: error,
                    cancelPayment: { [weak self] in
                        // TODO: this should also call CardPresentPaymentFacade.cancelPayment
                        cancelPayment()
                        self?.paymentEventSubject.send(.idle)
                    })))
        default:
            paymentEventSubject.send(.show(eventDetails: eventDetails))
        }
    }

    func presentWCSettingsWebView(adminURL: URL, completion: @escaping () -> Void) {
        // Web view support in SwiftUI is in the alert's implementation of `CardPresentPaymentsModalViewModelWCSettingsWebViewPresenting`
    }

    func foundSeveralReaders(readerIDs: [String], connect: @escaping (String) -> Void, cancelSearch: @escaping () -> Void) {
        let wrappedConnectionHandler = { [weak self] (readerID: String?) in
            if let readerID {
                connect(readerID)
            } else {
                cancelSearch()
            }
            self?.latestReaderConnectionHandler = nil
        }
        self.latestReaderConnectionHandler = wrappedConnectionHandler
        paymentEventSubject.send(.show(eventDetails: .foundMultipleReaders(readerIDs: readerIDs, selectionHandler: wrappedConnectionHandler)))
    }

    func updateSeveralReadersList(readerIDs: [String]) {
        guard let latestReaderConnectionHandler else {
            paymentEventSubject.send(.idle) // TODO: Consider more error handling here
            return
        }
        paymentEventSubject.send(.show(eventDetails: .foundMultipleReaders(readerIDs: readerIDs, selectionHandler: latestReaderConnectionHandler)))
    }

    func dismiss() {
        paymentEventSubject.send(.idle)
    }

    func reset() {
        latestReaderConnectionHandler = nil
    }
}
