import Foundation
import PointOfSale
import enum Yosemite.CardReaderServiceError

struct CardPresentPaymentBluetoothReaderConnectionAlertsProvider: BluetoothReaderConnnectionAlertsProviding {
    typealias AlertDetails = CardPresentPaymentEventDetails
    func scanningForReader(cancel: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .scanningForReaders(endSearch: cancel)
    }

    func scanningFailed(error: any Error,
                        close: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
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
                          retrySearch: @escaping @MainActor @Sendable () -> Void,
                          cancelSearch: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .connectingFailed(error: error,
                          retrySearch: retrySearch,
                          endSearch: cancelSearch)
    }

    func connectingFailedNonRetryable(error: any Error,
                                      close: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .connectingFailedNonRetryable(error: error,
                                      endSearch: close)
    }

    func connectingFailedIncompleteAddress(wcSettingsAdminURL: URL?,
                                           showsInAuthenticatedWebView: Bool,
                                           openWCSettings: (@MainActor @Sendable () -> Void)?,
                                           retrySearch: @escaping @MainActor @Sendable () -> Void,
                                           cancelSearch: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
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

    func connectingFailedInvalidPostalCode(retrySearch: @escaping @MainActor @Sendable () -> Void,
                                           cancelSearch: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .connectingFailedUpdatePostalCode(retrySearch: retrySearch,
                                          endSearch: cancelSearch)
    }

    func updatingFailed(tryAgain: (@MainActor @Sendable () -> Void)?,
                        close: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        if let tryAgain {
            .updateFailed(tryAgain: tryAgain,
                          cancelUpdate: close)
        } else {
            .updateFailedNonRetryable(cancelUpdate: close)
        }
    }

    func updateProgress(requiredUpdate: Bool,
                        progress: Float,
                        cancel: (@MainActor @Sendable () -> Void)?) -> CardPresentPaymentEventDetails {
        .updateProgress(requiredUpdate: requiredUpdate,
                        progress: progress,
                        cancelUpdate: cancel)
    }

    func selectSearchType(tapToPay: @escaping @MainActor @Sendable () -> Void,
                          bluetooth: @escaping @MainActor @Sendable () -> Void,
                          cancel: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .selectSearchType(tapToPay: tapToPay,
                          bluetooth: bluetooth,
                          endSearch: cancel)
    }

    func foundReader(name: String,
                     connect: @escaping @MainActor @Sendable () -> Void,
                     continueSearch: @escaping @MainActor @Sendable () -> Void,
                     cancelSearch: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .foundReader(name: name,
                     connect: connect,
                     continueSearch: continueSearch,
                     endSearch: cancelSearch)
    }

    func connectingFailedCriticallyLowBattery(retrySearch: @escaping @MainActor @Sendable () -> Void,
                                              cancelSearch: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .connectingFailedChargeReader(retrySearch: retrySearch,
                                      endSearch: cancelSearch)
    }

    func updatingFailedLowBattery(batteryLevel: Double?,
                                  retrySearch: @escaping @MainActor @Sendable () -> Void,
                                  close: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .updateFailedLowBattery(batteryLevel: batteryLevel,
                                retrySearch: retrySearch,
                                cancelUpdate: close)
    }

    func locationRequestPreAlert(requestPermission: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .locationRequestPreAlert(requestPermission: requestPermission)
    }

    func locationRequired(cancel: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .locationRequired(cancel: cancel)
    }
}
