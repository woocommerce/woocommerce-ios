import Foundation
import PointOfSale
import UIKit
import Yosemite

final class POSRefundOrderDetailsPaymentAlerts: OrderDetailsPaymentAlertsProtocol {
    private let stateModel: POSRefundSubmissionModel
    private let alertsProvider = CardPresentPaymentsTransactionAlertsProvider()

    init(stateModel: POSRefundSubmissionModel) {
        self.stateModel = stateModel
    }

    func presentViewModel(viewModel: CardPresentPaymentsModalViewModel) {
        // POS renders refund progress through POSRefundSubmissionModel instead of UIKit modal view models.
    }

    func preparingReader(onCancel: @escaping () -> Void) {
        present(alertsProvider.preparingReader(onCancel: onCancel))
    }

    func tapOrInsertCard(title: String, amount: String, inputMethods: CardReaderInput, onCancel: @escaping () -> Void) {
        present(alertsProvider.tapOrInsertCard(title: title, amount: amount, inputMethods: inputMethods, onCancel: onCancel))
    }

    func displayReaderMessage(message: String) {
        present(alertsProvider.displayReaderMessage(message: message))
    }

    func processingPayment(title: String) {
        present(alertsProvider.processingTransaction(title: title))
    }

    func error(error: Error, tryAgain: @escaping () -> Void, dismissCompletion: @escaping () -> Void) {
        present(alertsProvider.error(error: error,
                                     receiptState: .noEmailReceipt,
                                     tryAgain: tryAgain,
                                     dismissCompletion: dismissCompletion))
    }

    func nonRetryableError(from: UIViewController?, error: Error, dismissCompletion: @escaping () -> Void) {
        present(alertsProvider.nonRetryableError(error: error,
                                                 receiptState: .noEmailReceipt,
                                                 dismissCompletion: dismissCompletion))
    }

    private func present(_ eventDetails: CardPresentPaymentEventDetails) {
        onMainQueue { [stateModel] in
            stateModel.state = .cardPresentEvent(eventDetails)
        }
    }
}

final class POSRefundCardPresentPaymentAlertsPresenter: CardPresentPaymentAlertsPresenting {
    typealias AlertDetails = CardPresentPaymentEventDetails

    private let stateModel: POSRefundSubmissionModel
    private var latestReaderConnectionHandler: ((String?) -> Void)?

    init(stateModel: POSRefundSubmissionModel) {
        self.stateModel = stateModel
    }

    func present(viewModel eventDetails: CardPresentPaymentEventDetails) {
        switch eventDetails {
        case .paymentError(error: CollectOrderPaymentUseCaseError.orderAlreadyPaid, _, _):
            present(.paymentSuccess(done: {}))
        case .paymentError(error: ServerSidePaymentCaptureError.paymentGateway, _, let cancelPayment):
            present(.paymentCaptureError(cancelPayment: { [weak self] in
                cancelPayment()
                self?.dismiss()
            }))
        case .paymentError(error: CardReaderServiceError.intentCreation(let underlyingError), _, let cancelPayment):
            present(.paymentIntentCreationError(error: underlyingError, cancelPayment: { [weak self] in
                cancelPayment()
                self?.dismiss()
            }))
        case .paymentError(let error, let retryApproach, let cancelPayment):
            present(.paymentError(error: error,
                                  retryApproach: retryApproach,
                                  cancelPayment: { [weak self] in
                cancelPayment()
                self?.dismiss()
            }))
        case .scanningForReaders(let endSearch):
            present(.scanningForReaders(endSearch: { [weak self] in
                endSearch()
                self?.dismiss()
            }))
        case .foundReader(let name, let connect, let continueSearch, let endSearch):
            present(.foundReader(name: name,
                                 connect: connect,
                                 continueSearch: continueSearch,
                                 endSearch: { [weak self] in
                endSearch()
                self?.dismiss()
            }))
        case .locationRequired(let cancel):
            present(.locationRequired(cancel: { [weak self] in
                cancel()
                self?.dismiss()
            }))
        default:
            present(eventDetails)
        }
    }

    func presentWCSettingsWebView(adminURL: URL, completion: @escaping () -> Void) {
        // The POS connection alert view handles opening settings URLs from its view model.
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
        latestReaderConnectionHandler = wrappedConnectionHandler
        present(.foundMultipleReaders(readerIDs: readerIDs, selectionHandler: wrappedConnectionHandler))
    }

    func updateSeveralReadersList(readerIDs: [String]) {
        guard let latestReaderConnectionHandler else {
            dismiss()
            return
        }
        present(.foundMultipleReaders(readerIDs: readerIDs, selectionHandler: latestReaderConnectionHandler))
    }

    func dismiss() {
        onMainQueue { [stateModel] in
            stateModel.reset()
        }
    }

    func reset() {
        latestReaderConnectionHandler = nil
    }

    private func present(_ eventDetails: CardPresentPaymentEventDetails) {
        onMainQueue { [stateModel] in
            stateModel.state = .cardPresentEvent(eventDetails)
        }
    }
}

private func onMainQueue(_ update: @escaping () -> Void) {
    if Thread.isMainThread {
        update()
    } else {
        DispatchQueue.main.async(execute: update)
    }
}
