import Foundation
import Combine

final class CardPresentPaymentsAlertPresenterAdaptor: CardPresentPaymentAlertsPresenting {
    typealias AlertDetails = CardPresentPaymentAlertDetails
    let paymentAlertPublisher: AnyPublisher<CardPresentPaymentEvent, Never>

    private let paymentAlertSubject: PassthroughSubject<CardPresentPaymentEvent, Never> = PassthroughSubject()

    private var latestReaderConnectionHandler: ((String?) -> Void)?

    init() {
        paymentAlertPublisher = paymentAlertSubject.eraseToAnyPublisher()
    }

    func present(viewModel: CardPresentPaymentAlertDetails) {
        switch viewModel {
            case .scanningForReaders(let endSearch):
                // TODO: hide it in collectPayment flow
                paymentAlertSubject.send(.showAlert(.scanningForReaders(viewModel: .init(endSearchAction: endSearch))))
            case .scanningFailed(let error, let endSearch):
            paymentAlertSubject.send(.showAlert(.scanningFailed(viewModel: .init(error: error, endSearchAction: endSearch))))
            case .bluetoothRequired(let error, let endSearch):
            paymentAlertSubject.send(.showAlert(.bluetoothRequired(viewModel: .init(error: error, endSearch: endSearch))))
            case .connectingToReader:
                // TODO: hide it in collectPayment flow
                paymentAlertSubject.send(.showAlert(.connectingToReader(viewModel: .init())))
            case .connectingFailed(let error, let retrySearch, let endSearch):
            paymentAlertSubject.send(.showAlert(.connectingFailed(viewModel: .init(error: error, retryButtonAction: retrySearch, cancelButtonAction: endSearch))))
            case .connectingFailedNonRetryable(let error, let endSearch):
            paymentAlertSubject.send(.showAlert(.connectingFailedNonRetryable(viewModel: .init(error: error, cancelAction: endSearch))))
            case .connectingFailedUpdatePostalCode(let retrySearch, let endSearch):
                paymentAlertSubject.send(.showAlert(.connectingFailedUpdatePostalCode(viewModel: .init())))
            case .connectingFailedChargeReader(let retrySearch, let endSearch):
            paymentAlertSubject.send(.showAlert(.connectingFailedChargeReader(viewModel: .init(
                retryButtonAction: retrySearch,
                cancelButtonAction: endSearch))))
            case .connectingFailedUpdateAddress(let wcSettingsAdminURL, let retrySearch, let endSearch):
                paymentAlertSubject.send(.showAlert(.connectingFailedUpdateAddress(
                    viewModel: CardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
                        settingsAdminUrl: wcSettingsAdminURL,
                        retrySearchAction: retrySearch,
                        cancelSearchAction: endSearch))))
            case .preparingForPayment(let cancelPayment):
                paymentAlertSubject.send(.showPaymentMessage(.preparingForPayment))
            // TODO: support this case
            case .selectSearchType(let tapToPay, let bluetooth, let endSearch):
                fatalError("Not supported")
            case .foundReader(let name, let connect, let continueSearch, let endSearch):
                paymentAlertSubject.send(.showAlert(.foundReader(viewModel: .init(readerName: name,
                                                                                  connectAction: connect,
                                                                                  continueSearchAction: continueSearch,
                                                                                  endSearchAction: endSearch))))
            case .updateProgress(let requiredUpdate, let progress, let cancelUpdate):
                paymentAlertSubject.send(.showAlert(.updatingReader(viewModel: .init())))
            case .updateFailed(let tryAgain, let cancelUpdate):
                paymentAlertSubject.send(.showAlert(.updateFailed(viewModel: .init())))
            case .updateFailedNonRetryable(let cancelUpdate):
                paymentAlertSubject.send(.showAlert(.updateFailed(viewModel: .init())))
            case .updateFailedLowBattery(let batteryLevel, let cancelUpdate):
                paymentAlertSubject.send(.showAlert(.updateFailed(viewModel: .init())))
            case .tapSwipeOrInsertCard(let inputMethods, let cancelPayment):
                paymentAlertSubject.send(.showPaymentMessage(.tapSwipeOrInsertCard))
            case .success(let done):
                paymentAlertSubject.send(.showPaymentMessage(.success))
            // TODO: separate error into two error types for `showAlert` and `showPaymentMessage` depending on the type of error
            case .error(let error, let tryAgain, let cancelPayment):
                paymentAlertSubject.send(.showPaymentMessage(.error))
            // TODO: separate error into two error types for `showAlert` and `showPaymentMessage` depending on the type of error
            case .errorNonRetryable(let error, let cancelPayment):
                paymentAlertSubject.send(.showPaymentMessage(.error))
            case .processing:
                paymentAlertSubject.send(.showPaymentMessage(.processing))
            case .displayReaderMessage(let message):
                paymentAlertSubject.send(.showPaymentMessage(.displayReaderMessage(message: message)))
            // TODO: support this case
            case .cancelledOnReader:
                fatalError("Not supported")
            case .validatingOrder(let cancelPayment):
                paymentAlertSubject.send(.showPaymentMessage(.preparingForPayment))
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
