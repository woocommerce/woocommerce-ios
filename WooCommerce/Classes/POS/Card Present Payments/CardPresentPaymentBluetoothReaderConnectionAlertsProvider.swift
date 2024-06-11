import Foundation

struct CardPresentPaymentBluetoothReaderConnectionAlertsProvider: BluetoothReaderConnnectionAlertsProviding {
    typealias AlertDetails = CardPresentPaymentAlertDetails
    func scanningForReader(cancel: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .scanningForReaders
    }

    func scanningFailed(error: any Error,
                        close: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .scanningFailed
    }

    func connectingToReader() -> CardPresentPaymentAlertDetails {
        .connectingToReader
    }

    func connectingFailed(error: any Error,
                          retrySearch: @escaping () -> Void,
                          cancelSearch: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .connectingFailed
    }

    func connectingFailedNonRetryable(error: any Error,
                                      close: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .errorNonRetryable
    }

    func connectingFailedIncompleteAddress(wcSettingsAdminURL: URL?,
                                           openWCSettings: (() -> Void)?,
                                           retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .connectingFailedUpdateAddress
    }

    func connectingFailedInvalidPostalCode(retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .connectingFailedUpdatePostalCode
    }

    func updatingFailed(tryAgain: (() -> Void)?,
                        close: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .updateFailed
    }

    func updateProgress(requiredUpdate: Bool,
                        progress: Float,
                        cancel: (() -> Void)?) -> CardPresentPaymentAlertDetails {
        .updateProgress
    }

    func selectSearchType(tapToPay: @escaping () -> Void,
                          bluetooth: @escaping () -> Void,
                          cancel: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .selectSearchType
    }

    func foundReader(name: String, connect: @escaping () -> Void, continueSearch: @escaping () -> Void, cancelSearch: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .foundReader
    }

    func connectingFailedCriticallyLowBattery(retrySearch: @escaping () -> Void, cancelSearch: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .connectingFailedChargeReader
    }

    func updatingFailedLowBattery(batteryLevel: Double?, close: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .updateFailedLowBattery
    }
}
