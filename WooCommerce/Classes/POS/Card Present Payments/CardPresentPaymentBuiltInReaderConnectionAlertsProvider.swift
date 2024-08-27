import Foundation

struct CardPresentPaymentBuiltInReaderConnectionAlertsProvider: CardReaderConnectionAlertsProviding {
    typealias AlertDetails = CardPresentPaymentEventDetails
    func scanningForReader(cancel: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .scanningForReaders(endSearch: cancel)
    }

    func scanningFailed(error: any Error,
                        close: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .scanningFailed(error: error,
                        endSearch: close)
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
}
