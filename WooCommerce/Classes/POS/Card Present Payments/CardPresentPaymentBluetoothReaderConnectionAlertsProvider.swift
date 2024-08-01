import Foundation
import enum Yosemite.CardReaderServiceError

struct CardPresentPaymentBluetoothReaderConnectionAlertsProvider: BluetoothReaderConnnectionAlertsProviding {
    typealias AlertDetails = CardPresentPaymentEventDetails
    func scanningForReader(cancel: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .scanningForReaders(endSearch: cancel)
    }

    func scanningFailed(error: any Error,
                        close: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        switch error {
        case CardReaderServiceError.bluetoothDenied:
            return .bluetoothRequired(error: error, endSearch: close)
        default:
            return .scanningFailed(error: error, endSearch: close)
        }
    }

    func connectingToReader() -> CardPresentPaymentEventDetails {
        .connectingToReader
    }

    func connectingFailed(error: any Error,
                          retrySearch: @escaping () -> Void,
                          cancelSearch: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .connectingFailed(error: error,
                          retrySearch: retrySearch,
                          endSearch: cancelSearch)
    }

    func connectingFailedNonRetryable(error: any Error,
                                      close: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .connectingFailedNonRetryable(error: error,
                                      endSearch: close)
    }

    func connectingFailedIncompleteAddress(wcSettingsAdminURL: URL?,
                                           showsInAuthenticatedWebView: Bool,
                                           openWCSettings: (() -> Void)?,
                                           retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        guard let wcSettingsAdminURL else {
            return .connectingFailedNonRetryable(
                error: CardPresentPaymentServiceError.incompleteAddressConnectionError,
                endSearch: cancelSearch)
        }
        return .connectingFailedUpdateAddress(wcSettingsAdminURL: wcSettingsAdminURL,
                                              showsInAuthenticatedWebView: showsInAuthenticatedWebView,
                                              retrySearch: retrySearch,
                                              endSearch: cancelSearch)
    }

    func connectingFailedInvalidPostalCode(retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .connectingFailedUpdatePostalCode(retrySearch: retrySearch,
                                          endSearch: cancelSearch)
    }

    func updatingFailed(tryAgain: (() -> Void)?,
                        close: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        if let tryAgain {
            .updateFailed(tryAgain: tryAgain,
                          cancelUpdate: close)
        } else {
            .updateFailedNonRetryable(cancelUpdate: close)
        }
    }

    func updateProgress(requiredUpdate: Bool,
                        progress: Float,
                        cancel: (() -> Void)?) -> CardPresentPaymentEventDetails {
        .updateProgress(requiredUpdate: requiredUpdate,
                        progress: progress,
                        cancelUpdate: cancel)
    }

    func selectSearchType(tapToPay: @escaping () -> Void,
                          bluetooth: @escaping () -> Void,
                          cancel: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .selectSearchType(tapToPay: tapToPay,
                          bluetooth: bluetooth,
                          endSearch: cancel)
    }

    func foundReader(name: String,
                     connect: @escaping () -> Void,
                     continueSearch: @escaping () -> Void,
                     cancelSearch: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .foundReader(name: name,
                     connect: connect,
                     continueSearch: continueSearch,
                     endSearch: cancelSearch)
    }

    func connectingFailedCriticallyLowBattery(retrySearch: @escaping () -> Void, cancelSearch: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .connectingFailedChargeReader(retrySearch: retrySearch,
                                      endSearch: cancelSearch)
    }

    func updatingFailedLowBattery(batteryLevel: Double?, close: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .updateFailedLowBattery(batteryLevel: batteryLevel,
                                cancelUpdate: close)
    }
}
