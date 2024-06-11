import Foundation

struct CardPresentPaymentBuiltInReaderConnectionAlertsProvider: CardReaderConnectionAlertsProviding {
    typealias AlertDetails = CardPresentPaymentAlertDetails
    func scanningForReader(cancel: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .scanningForReaders(cancel: cancel)
    }

    func scanningFailed(error: any Error,
                        close: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .scanningFailed(error: error,
                        close: close)
    }

    func connectingToReader() -> CardPresentPaymentAlertDetails {
        .connectingToReader
    }

    func connectingFailed(error: any Error,
                          retrySearch: @escaping () -> Void,
                          cancelSearch: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .connectingFailed(error: error,
                          retrySearch: retrySearch,
                          cancelSearch: cancelSearch)
    }

    func connectingFailedNonRetryable(error: any Error,
                                      close: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .connectingFailedNonRetryable(error: error,
                                      close: close)
    }

    func connectingFailedIncompleteAddress(wcSettingsAdminURL: URL?,
                                           openWCSettings: (() -> Void)?,
                                           retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .connectingFailedUpdateAddress(wcSettingsAdminURL: wcSettingsAdminURL,
                                       retrySearch: retrySearch, 
                                       cancelSearch: cancelSearch)
    }

    func connectingFailedInvalidPostalCode(retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .connectingFailedUpdatePostalCode(retrySearch: retrySearch,
                                          cancelSearch: cancelSearch)
    }

    func updatingFailed(tryAgain: (() -> Void)?,
                        close: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .updateFailed(tryAgain: tryAgain,
                      close: close)
    }

    func updateProgress(requiredUpdate: Bool,
                        progress: Float,
                        cancel: (() -> Void)?) -> CardPresentPaymentAlertDetails {
        .updateProgress(requiredUpdate: requiredUpdate,
                        progress: progress,
                        cancel: cancel)
    }

    func selectSearchType(tapToPay: @escaping () -> Void,
                          bluetooth: @escaping () -> Void,
                          cancel: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .selectSearchType(tapToPay: tapToPay,
                          bluetooth: bluetooth,
                          cancel: cancel)
    }
}
