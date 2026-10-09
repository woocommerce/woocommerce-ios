import Foundation
import UIKit

struct TapToPayReaderConnectionAlertsProvider: CardReaderConnectionAlertsProviding {
    func scanningForReader(cancel: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalTapToPayReaderCheckingDeviceSupport(cancel: cancel)
    }

    func scanningFailed(error: Error,
                        close: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalScanningFailed(error: error, image: .tapToPayReaderError, primaryAction: close)
    }

    func connectingToReader() -> CardPresentPaymentsModalViewModel {
        CardPresentModalTapToPayConnectingToReader()
    }

    func connectingFailed(error: Error,
                          retrySearch: @escaping @MainActor @Sendable () -> Void,
                          cancelSearch: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalTapToPayConnectingFailed(error: error,
                                                 continueSearch: retrySearch,
                                                 cancelSearch: cancelSearch)
    }

    func connectingFailedNonRetryable(error: Error, close: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalTapToPayConnectingFailedNonRetryable(error: error,
                                                             close: close)
    }


    func connectingFailedIncompleteAddress(wcSettingsAdminURL: URL?,
                                           showsInAuthenticatedWebView: Bool,
                                           openWCSettings: (@MainActor @Sendable () -> Void)?,
                                           retrySearch: @escaping @MainActor @Sendable () -> Void,
                                           cancelSearch: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailedUpdateAddress(image: .tapToPayReaderError,
                                                      wcSettingsAdminURL: wcSettingsAdminURL,
                                                      openWCSettings: openWCSettings,
                                                      retrySearch: retrySearch,
                                                      cancelSearch: cancelSearch)
    }

    func connectingFailedInvalidPostalCode(retrySearch: @escaping @MainActor @Sendable () -> Void,
                                           cancelSearch: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailedUpdatePostalCode(image: .tapToPayReaderError,
                                                         retrySearch: retrySearch,
                                                         cancelSearch: cancelSearch)
    }

    func updatingFailed(tryAgain: (@MainActor @Sendable () -> Void)?,
                        close: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        if let tryAgain {
            return CardPresentModalUpdateFailed(image: .tapToPayReaderError, tryAgain: tryAgain, close: close)
        } else {
            return CardPresentModalUpdateFailedNonRetryable(image: .tapToPayReaderError, close: close)
        }
    }

    func updateProgress(requiredUpdate: Bool,
                        progress: Float,
                        cancel: (@MainActor @Sendable () -> Void)?) -> CardPresentPaymentsModalViewModel {
        CardPresentModalTapToPayConfigurationProgress(progress: progress, cancel: cancel)
    }

    func selectSearchType(tapToPay: @escaping @MainActor @Sendable () -> Void,
                          bluetooth: @escaping @MainActor @Sendable () -> Void,
                          cancel: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalSelectSearchType(tapOnIPhoneAction: tapToPay, bluetoothAction: bluetooth, cancelAction: cancel)
    }

    func locationRequestPreAlert(requestPermission: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalLocationPreAlert(requestPermission: requestPermission)
    }

    func locationRequired(cancel: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalLocationRequired(cancel: cancel)
    }
}
