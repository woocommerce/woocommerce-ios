import Foundation
import Yosemite
import UIKit

struct BluetoothReaderConnectionAlertsProvider: BluetoothReaderConnnectionAlertsProviding {
    typealias AlertDetails = CardPresentPaymentsModalViewModel
    func scanningForReader(cancel: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalScanningForReader(cancel: cancel)
    }

    func scanningFailed(error: Error,
                        close: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        switch error {
        case CardReaderServiceError.bluetoothDenied, CardReaderServiceError.discovery(underlyingError: .bluetoothDenied):
            return CardPresentModalBluetoothRequired(error: error, primaryAction: close)
        default:
            return CardPresentModalScanningFailed(error: error, primaryAction: close)
        }
    }

    func connectingToReader() -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingToReader()
    }

    func connectingFailed(error: Error,
                          retrySearch: @escaping @MainActor @Sendable () -> Void,
                          cancelSearch: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailed(error: error, retrySearch: retrySearch, cancelSearch: cancelSearch)
    }

    func connectingFailedNonRetryable(error: Error, close: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalNonRetryableErrorWithoutEmail(amount: "", error: error, onDismiss: close)
    }

    func connectingFailedIncompleteAddress(wcSettingsAdminURL: URL?,
                                           showsInAuthenticatedWebView: Bool,
                                           openWCSettings: (@MainActor @Sendable () -> Void)?,
                                           retrySearch: @escaping @MainActor @Sendable () -> Void,
                                           cancelSearch: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailedUpdateAddress(wcSettingsAdminURL: wcSettingsAdminURL,
                                                      openWCSettings: openWCSettings,
                                                      retrySearch: retrySearch,
                                                      cancelSearch: cancelSearch)
    }

    func connectingFailedInvalidPostalCode(retrySearch: @escaping @MainActor @Sendable () -> Void,
                                           cancelSearch: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailedUpdatePostalCode(retrySearch: retrySearch, cancelSearch: cancelSearch)
    }

    func updatingFailed(tryAgain: (@MainActor @Sendable () -> Void)?,
                        close: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        if let tryAgain {
            return CardPresentModalUpdateFailed(tryAgain: tryAgain, close: close)
        } else {
            return CardPresentModalUpdateFailedNonRetryable(close: close)
        }
    }
    func updateProgress(requiredUpdate: Bool,
                        progress: Float,
                        cancel: (@MainActor @Sendable () -> Void)?) -> CardPresentPaymentsModalViewModel {
        CardPresentModalUpdateProgress(requiredUpdate: requiredUpdate, progress: progress, cancel: cancel)
    }

    func selectSearchType(tapToPay: @escaping @MainActor @Sendable () -> Void,
                          bluetooth: @escaping @MainActor @Sendable () -> Void,
                          cancel: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalSelectSearchType(tapOnIPhoneAction: tapToPay, bluetoothAction: bluetooth, cancelAction: cancel)
    }

    func foundReader(name: String,
                     connect: @escaping @MainActor @Sendable () -> Void,
                     continueSearch: @escaping @MainActor @Sendable () -> Void,
                     cancelSearch: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalFoundReader(name: name, connect: connect, continueSearch: continueSearch, cancel: cancelSearch)
    }

    func connectingFailedCriticallyLowBattery(retrySearch: @escaping @MainActor @Sendable () -> Void,
                                              cancelSearch: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailedChargeReader(retrySearch: retrySearch, cancelSearch: cancelSearch)
    }

    func updatingFailedLowBattery(batteryLevel: Double?,
                                  retrySearch: @escaping @MainActor @Sendable () -> Void,
                                  close: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalUpdateFailedLowBattery(batteryLevel: batteryLevel, retrySearch: retrySearch, close: close)
    }

    func locationRequestPreAlert(requestPermission: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalLocationPreAlert(requestPermission: requestPermission)
    }

    func locationRequired(cancel: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalLocationRequired(cancel: cancel)
    }
}
