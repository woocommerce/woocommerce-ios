import Foundation
import UIKit

struct BuiltInReaderConnectionAlertsProvider: CardReaderConnectionAlertsProviding {
    func scanningForReader(cancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalScanningForReader(cancel: cancel)
    }

    func scanningFailed(error: Error, close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalScanningFailed(error: error, primaryAction: close)
    }

    func connectingToReader() -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingToReader()
    }

    func connectingFailed(continueSearch: @escaping () -> Void, cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailed(continueSearch: continueSearch, cancelSearch: cancelSearch)
    }

    func connectingFailedIncompleteAddress(openWCSettings: ((UIViewController) -> Void)?,
                                           retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailedUpdateAddress(openWCSettings: openWCSettings, retrySearch: retrySearch, cancelSearch: cancelSearch)
    }

    func connectingFailedInvalidPostalCode(retrySearch: @escaping () -> Void, cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailedUpdatePostalCode(retrySearch: retrySearch, cancelSearch: cancelSearch)
    }

    func updatingFailed(tryAgain: (() -> Void)?, close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        if let tryAgain = tryAgain {
            return CardPresentModalUpdateFailed(tryAgain: tryAgain, close: close)
        } else {
            return CardPresentModalUpdateFailedNonRetryable(close: close)
        }
    }
    func updateProgress(requiredUpdate: Bool, progress: Float, cancel: (() -> Void)?) -> CardPresentPaymentsModalViewModel {
        CardPresentModalUpdateProgress(requiredUpdate: requiredUpdate, progress: progress, cancel: cancel)
    }
}
