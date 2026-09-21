import Foundation
import PointOfSale
import UIKit
import Yosemite

final class POSRefundOrderDetailsPaymentAlerts: OrderDetailsPaymentAlertsProtocol {
    private let stateModel: POSRefundSubmissionModel
    private let onCancelRequested: () -> Void
    private let isPresentationAllowed: () -> Bool
    private let alertsProvider = CardPresentPaymentsTransactionAlertsProvider()

    init(stateModel: POSRefundSubmissionModel,
         onCancelRequested: @escaping () -> Void = {},
         isPresentationAllowed: @escaping () -> Bool = { true }) {
        self.stateModel = stateModel
        self.onCancelRequested = onCancelRequested
        self.isPresentationAllowed = isPresentationAllowed
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

    func cardInserted(title: String, amount: String, onCancel: @escaping () -> Void) {
        present(alertsProvider.cardInserted(title: title, amount: amount, onCancel: onCancel))
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
        let eventDetails = eventDetails.markingPOSCancellation(onCancelRequested)
        onMainQueue { [stateModel, isPresentationAllowed] in
            guard isPresentationAllowed() else { return }
            stateModel.state = .cardPresentEvent(eventDetails)
        }
    }
}

final class POSRefundCardPresentPaymentAlertsPresenter: CardPresentPaymentAlertsPresenting {
    typealias AlertDetails = CardPresentPaymentEventDetails

    private let stateModel: POSRefundSubmissionModel
    private let onCancelRequested: () -> Void
    private let isPresentationAllowed: () -> Bool
    private var latestReaderConnectionHandler: ((String?) -> Void)?

    init(stateModel: POSRefundSubmissionModel,
         onCancelRequested: @escaping () -> Void = {},
         isPresentationAllowed: @escaping () -> Bool = { true }) {
        self.stateModel = stateModel
        self.onCancelRequested = onCancelRequested
        self.isPresentationAllowed = isPresentationAllowed
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
        let eventDetails = eventDetails.markingPOSCancellation(onCancelRequested)
        onMainQueue { [stateModel, isPresentationAllowed] in
            guard isPresentationAllowed() else { return }
            stateModel.state = .cardPresentEvent(eventDetails)
        }
    }
}

private extension CardPresentPaymentEventDetails {
    func markingPOSCancellation(_ markCancelled: @escaping () -> Void) -> Self {
        let markAndRun: (@escaping () -> Void) -> () -> Void = { action in
            {
                markCancelled()
                action()
            }
        }

        switch self {
        case .scanningForReaders(let endSearch):
            return .scanningForReaders(endSearch: markAndRun(endSearch))
        case .scanningFailed(let error, let endSearch):
            return .scanningFailed(error: error, endSearch: markAndRun(endSearch))
        case .bluetoothRequired(let error, let endSearch):
            return .bluetoothRequired(error: error, endSearch: markAndRun(endSearch))
        case .connectingFailed(let error, let retrySearch, let endSearch):
            return .connectingFailed(error: error,
                                     retrySearch: retrySearch,
                                     endSearch: markAndRun(endSearch))
        case .connectingFailedNonRetryable(let error, let endSearch):
            return .connectingFailedNonRetryable(error: error,
                                                 endSearch: markAndRun(endSearch))
        case .connectingFailedUpdatePostalCode(let retrySearch, let endSearch):
            return .connectingFailedUpdatePostalCode(retrySearch: retrySearch,
                                                     endSearch: markAndRun(endSearch))
        case .connectingFailedChargeReader(let retrySearch, let endSearch):
            return .connectingFailedChargeReader(retrySearch: retrySearch,
                                                 endSearch: markAndRun(endSearch))
        case .connectingFailedUpdateAddress(let adminURL, let showsInAuthenticatedWebView, let retrySearch, let endSearch):
            return .connectingFailedUpdateAddress(wcSettingsAdminURL: adminURL,
                                                  showsInAuthenticatedWebView: showsInAuthenticatedWebView,
                                                  retrySearch: retrySearch,
                                                  endSearch: markAndRun(endSearch))
        case .preparingForPayment(let cancelPayment):
            return .preparingForPayment(cancelPayment: markAndRun(cancelPayment))
        case .selectSearchType(let tapToPay, let bluetooth, let endSearch):
            return .selectSearchType(tapToPay: tapToPay,
                                     bluetooth: bluetooth,
                                     endSearch: markAndRun(endSearch))
        case .foundReader(let name, let connect, let continueSearch, let endSearch):
            return .foundReader(name: name,
                                connect: connect,
                                continueSearch: continueSearch,
                                endSearch: markAndRun(endSearch))
        case .foundMultipleReaders(let readerIDs, let selectionHandler):
            return .foundMultipleReaders(readerIDs: readerIDs) { readerID in
                if readerID == nil {
                    markCancelled()
                }
                selectionHandler(readerID)
            }
        case .updateProgress(let requiredUpdate, let progress, let cancelUpdate):
            return .updateProgress(requiredUpdate: requiredUpdate,
                                   progress: progress,
                                   cancelUpdate: cancelUpdate.map(markAndRun))
        case .updateFailed(let tryAgain, let cancelUpdate):
            return .updateFailed(tryAgain: tryAgain,
                                 cancelUpdate: markAndRun(cancelUpdate))
        case .updateFailedNonRetryable(let cancelUpdate):
            return .updateFailedNonRetryable(cancelUpdate: markAndRun(cancelUpdate))
        case .updateFailedLowBattery(let batteryLevel, let retrySearch, let cancelUpdate):
            return .updateFailedLowBattery(batteryLevel: batteryLevel,
                                           retrySearch: retrySearch,
                                           cancelUpdate: markAndRun(cancelUpdate))
        case .tapSwipeOrInsertCard(let inputMethods, let cancelPayment):
            return .tapSwipeOrInsertCard(inputMethods: inputMethods,
                                         cancelPayment: markAndRun(cancelPayment))
        case .cardInserted(let cancelPayment):
            return .cardInserted(cancelPayment: markAndRun(cancelPayment))
        case .paymentError(let error, let retryApproach, let cancelPayment):
            return .paymentError(error: error,
                                 retryApproach: retryApproach,
                                 cancelPayment: markAndRun(cancelPayment))
        case .paymentCaptureError(let cancelPayment):
            return .paymentCaptureError(cancelPayment: markAndRun(cancelPayment))
        case .paymentIntentCreationError(let error, let cancelPayment):
            return .paymentIntentCreationError(error: error,
                                               cancelPayment: markAndRun(cancelPayment))
        case .validatingOrder(let cancelPayment):
            return .validatingOrder(cancelPayment: markAndRun(cancelPayment))
        case .locationRequired(let cancel):
            return .locationRequired(cancel: markAndRun(cancel))
        case .connectingToReader, .connectionSuccess, .paymentSuccess, .processing,
                .displayReaderMessage, .cancelledOnReader, .paymentCancellationConfirmation, .locationRequestPreAlert:
            return self
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
