import Foundation
import UIKit

struct BluetoothReaderConnectionAlertsProvider: BluetoothReaderConnnectionAlertsProviding {
    func scanningForReader(cancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalScanningForReader(cancel: cancel)
    }

    func scanningFailed(error: Error,
                        close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalScanningFailed(error: error, primaryAction: close)
    }

    func connectingToReader() -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingToReader()
    }

    func connectingFailed(error: Error,
                          continueSearch: @escaping () -> Void,
                          cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailed(error: error, continueSearch: continueSearch, cancelSearch: cancelSearch)
    }

    func connectingFailedNonRetryable(error: Error, close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalNonRetryableError(amount: "", error: error, onDismiss: close)
    }

    func connectingFailedIncompleteAddress(openWCSettings: ((UIViewController) -> Void)?,
                                           retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailedUpdateAddress(openWCSettings: openWCSettings, retrySearch: retrySearch, cancelSearch: cancelSearch)
    }

    func connectingFailedInvalidPostalCode(retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailedUpdatePostalCode(retrySearch: retrySearch, cancelSearch: cancelSearch)
    }

    func updatingFailed(tryAgain: (() -> Void)?,
                        close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        if let tryAgain = tryAgain {
            return CardPresentModalUpdateFailed(tryAgain: tryAgain, close: close)
        } else {
            return CardPresentModalUpdateFailedNonRetryable(close: close)
        }
    }
    func updateProgress(requiredUpdate: Bool,
                        progress: Float,
                        cancel: (() -> Void)?) -> CardPresentPaymentsModalViewModel {
        CardPresentModalUpdateProgress(requiredUpdate: requiredUpdate, progress: progress, cancel: cancel)
    }

    func foundReader(name: String,
                     connect: @escaping () -> Void,
                     continueSearch: @escaping () -> Void,
                     cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalFoundReader(name: name, connect: connect, continueSearch: continueSearch, cancel: cancelSearch)
    }

    func connectingFailedCriticallyLowBattery(retrySearch: @escaping () -> Void,
                                              cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailedChargeReader(retrySearch: retrySearch, cancelSearch: cancelSearch)
    }

    func updatingFailedLowBattery(batteryLevel: Double?,
                                  close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalUpdateFailedLowBattery(batteryLevel: batteryLevel, close: close)
    }

}
