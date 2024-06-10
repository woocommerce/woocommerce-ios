import Foundation
import Combine

final class CardPresentPaymentsAlertPresenterAdaptor: CardPresentPaymentAlertsPresenting {
    let paymentAlertPublisher: AnyPublisher<CardPresentPaymentEvent, Never>

    private let paymentAlertSubject: PassthroughSubject<CardPresentPaymentEvent, Never> = PassthroughSubject()

    private var latestReaderConnectionHandler: ((String) -> Void)?

    init() {
        paymentAlertPublisher = paymentAlertSubject.eraseToAnyPublisher()
    }

    func present(viewModel: CardPresentPaymentsModalViewModel) {
        paymentAlertSubject.send(.showAlert(viewModel))
    }

    func presentWCSettingsWebView(adminURL: URL, completion: @escaping () -> Void) {
        // Web view support in SwiftUI is in the alert's implementation of `CardPresentPaymentsModalViewModelWCSettingsWebViewPresenting`
    }

    func foundSeveralReaders(readerIDs: [String], connect: @escaping (String) -> Void, cancelSearch: @escaping () -> Void) {
        let wrappedConnectionHandler = { [weak self] readerID in
            connect(readerID)
            self?.latestReaderConnectionHandler = nil
        }
        self.latestReaderConnectionHandler = wrappedConnectionHandler
        paymentAlertSubject.send(.showReaderList(readerIDs, selectionHandler: wrappedConnectionHandler))
    }

    func updateSeveralReadersList(readerIDs: [String]) {
        guard let latestReaderConnectionHandler else {
            paymentAlertSubject.send(.idle) // TODO: Consider more error handling here
            return
        }
        paymentAlertSubject.send(.showReaderList(readerIDs, selectionHandler: latestReaderConnectionHandler))
    }

    func dismiss() {
        paymentAlertSubject.send(.idle)
    }

    func reset() {
        latestReaderConnectionHandler = nil
    }
}
