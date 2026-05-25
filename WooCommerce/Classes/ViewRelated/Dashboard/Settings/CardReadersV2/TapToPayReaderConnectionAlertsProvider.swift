import Foundation
import UIKit

struct TapToPayReaderConnectionAlertsProvider: CardReaderConnectionAlertsProviding {
    func scanningForReader(cancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalTapToPayReaderCheckingDeviceSupport(cancel: cancel)
    }

    func scanningFailed(error: Error,
                        close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalScanningFailed(error: error, image: .tapToPayReaderError, primaryAction: close)
    }

    func connectingToReader() -> CardPresentPaymentsModalViewModel {
        CardPresentModalTapToPayConnectingToReader()
    }

    func connectingFailed(error: Error,
                          retrySearch: @escaping () -> Void,
                          cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalTapToPayConnectingFailed(error: error,
                                                 continueSearch: retrySearch,
                                                 cancelSearch: cancelSearch)
    }

    func connectingFailedNonRetryable(error: Error, close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalTapToPayConnectingFailedNonRetryable(error: error,
                                                             close: close)
    }


    func connectingFailedIncompleteAddress(wcSettingsAdminURL: URL?,
                                           showsInAuthenticatedWebView: Bool,
                                           openWCSettings: (() -> Void)?,
                                           retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailedUpdateAddress(image: .tapToPayReaderError,
                                                      wcSettingsAdminURL: wcSettingsAdminURL,
                                                      openWCSettings: openWCSettings,
                                                      retrySearch: retrySearch,
                                                      cancelSearch: cancelSearch)
    }

    func connectingFailedInvalidPostalCode(retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailedUpdatePostalCode(image: .tapToPayReaderError,
                                                         retrySearch: retrySearch,
                                                         cancelSearch: cancelSearch)
    }

    func updatingFailed(tryAgain: (() -> Void)?,
                        close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        if let tryAgain {
            return CardPresentModalUpdateFailed(image: .tapToPayReaderError, tryAgain: tryAgain, close: close)
        } else {
            return CardPresentModalUpdateFailedNonRetryable(image: .tapToPayReaderError, close: close)
        }
    }

    func updateProgress(requiredUpdate: Bool,
                        progress: Float,
                        cancel: (() -> Void)?) -> CardPresentPaymentsModalViewModel {
        CardPresentModalTapToPayConfigurationProgress(progress: progress, cancel: cancel)
    }

    func selectSearchType(tapToPay: @escaping () -> Void,
                          bluetooth: @escaping () -> Void,
                          cancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalSelectSearchType(tapOnIPhoneAction: tapToPay, bluetoothAction: bluetooth, cancelAction: cancel)
    }

    func locationRequestPreAlert(requestPermission: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalLocationPreAlert(requestPermission: requestPermission)
    }

    func locationRequired(cancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalLocationRequired(cancel: cancel)
    }
}
