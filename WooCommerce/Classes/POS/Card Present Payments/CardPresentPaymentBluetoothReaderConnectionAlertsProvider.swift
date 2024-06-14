import Foundation

struct CardPresentPaymentBluetoothReaderConnectionAlertsProvider: BluetoothReaderConnnectionAlertsProviding {
    typealias AlertDetails = CardPresentPaymentAlertDetails
    func scanningForReader(cancel: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .scanningForReaders(endSearch: cancel)
    }

    func scanningFailed(error: any Error,
                        close: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .scanningFailed(error: error, endSearch: close)
    }

    func connectingToReader() -> CardPresentPaymentAlertDetails {
        .connectingToReader
    }

    func connectingFailed(error: any Error,
                          retrySearch: @escaping () -> Void,
                          cancelSearch: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .connectingFailed(error: error,
                          retrySearch: retrySearch,
                          endSearch: cancelSearch)
    }

    func connectingFailedNonRetryable(error: any Error,
                                      close: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .errorNonRetryable(error: error,
                           cancelPayment: close)
    }

    func connectingFailedIncompleteAddress(wcSettingsAdminURL: URL?,
                                           openWCSettings: (() -> Void)?,
                                           retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .connectingFailedUpdateAddress(wcSettingsAdminURL: wcSettingsAdminURL,
                                       retrySearch: retrySearch,
                                       endSearch: cancelSearch)
    }

    func connectingFailedInvalidPostalCode(retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .connectingFailedUpdatePostalCode(retrySearch: retrySearch,
                                          endSearch: cancelSearch)
    }

    func updatingFailed(tryAgain: (() -> Void)?,
                        close: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .updateFailed(tryAgain: tryAgain,
                      cancelUpdate: close)
    }

    func updateProgress(requiredUpdate: Bool,
                        progress: Float,
                        cancel: (() -> Void)?) -> CardPresentPaymentAlertDetails {
        .updateProgress(requiredUpdate: requiredUpdate,
                        progress: progress,
                        cancelUpdate: cancel)
    }

    func selectSearchType(tapToPay: @escaping () -> Void,
                          bluetooth: @escaping () -> Void,
                          cancel: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .selectSearchType(tapToPay: tapToPay,
                          bluetooth: bluetooth,
                          endSearch: cancel)
    }

    func foundReader(name: String,
                     connect: @escaping () -> Void,
                     continueSearch: @escaping () -> Void,
                     cancelSearch: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .foundReader(name: name,
                     connect: connect,
                     continueSearch: continueSearch,
                     endSearch: cancelSearch)
    }

    func connectingFailedCriticallyLowBattery(retrySearch: @escaping () -> Void, cancelSearch: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .connectingFailedChargeReader(retrySearch: retrySearch,
                                      endSearch: cancelSearch)
    }

    func updatingFailedLowBattery(batteryLevel: Double?, close: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .updateFailedLowBattery(batteryLevel: batteryLevel,
                                cancelUpdate: close)
    }
}
