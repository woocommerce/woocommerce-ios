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
        paymentEventSubject.send(.show(eventDetails: eventDetails))
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
        paymentEventSubject.send(.showReaderList(readerIDs, selectionHandler: wrappedConnectionHandler))
    }

    func updateSeveralReadersList(readerIDs: [String]) {
        guard let latestReaderConnectionHandler else {
            paymentEventSubject.send(.idle) // TODO: Consider more error handling here
            return
        }
        paymentEventSubject.send(.showReaderList(readerIDs, selectionHandler: latestReaderConnectionHandler))
    }

    func dismiss() {
        paymentEventSubject.send(.idle)
    }

    func reset() {
        latestReaderConnectionHandler = nil
    }
}
