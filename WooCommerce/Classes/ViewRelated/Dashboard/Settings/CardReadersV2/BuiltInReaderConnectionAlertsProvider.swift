import Foundation
import UIKit

struct BuiltInReaderConnectionAlertsProvider: CardReaderConnectionAlertsProviding {
    func scanningForReader(cancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalBuiltInReaderCheckingDeviceSupport(cancel: cancel)
    }

    func scanningFailed(error: Error,
                        close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalScanningFailed(error: error, image: .builtInReaderError, primaryAction: close)
    }

    func connectingToReader() -> CardPresentPaymentsModalViewModel {
        CardPresentModalBuiltInConnectingToReader()
    }

    func connectingFailed(error: Error,
                          retrySearch: @escaping () -> Void,
                          cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalBuiltInConnectingFailed(error: error,
                                                continueSearch: retrySearch,
                                                cancelSearch: cancelSearch)
    }

    func connectingFailedNonRetryable(error: Error, close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalBuiltInConnectingFailedNonRetryable(error: error,
                                                            close: close)
    }


    func connectingFailedIncompleteAddress(wcSettingsAdminURL: URL?,
                                           openWCSettings: (() -> Void)?,
                                           retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailedUpdateAddress(image: .builtInReaderError,
                                                      wcSettingsAdminURL: wcSettingsAdminURL,
                                                      openWCSettings: openWCSettings,
                                                      retrySearch: retrySearch,
                                                      cancelSearch: cancelSearch)
    }

    func connectingFailedInvalidPostalCode(retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailedUpdatePostalCode(image: .builtInReaderError,
                                                         retrySearch: retrySearch,
                                                         cancelSearch: cancelSearch)
    }

    func updatingFailed(tryAgain: (() -> Void)?,
                        close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        if let tryAgain = tryAgain {
            return CardPresentModalUpdateFailed(image: .builtInReaderError, tryAgain: tryAgain, close: close)
        } else {
            return CardPresentModalUpdateFailedNonRetryable(image: .builtInReaderError, close: close)
        }
    }

    func updateProgress(requiredUpdate: Bool,
                        progress: Float,
                        cancel: (() -> Void)?) -> CardPresentPaymentsModalViewModel {
        CardPresentModalBuiltInConfigurationProgress(progress: progress, cancel: cancel)
    }
}
