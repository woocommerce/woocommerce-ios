import UIKit
import Yosemite
import WordPressUI

/// A layer of indirection between our card reader settings view controllers and the modal alerts
/// presented to provide user-facing feedback as we discover, connect and manage card readers
///
final class CardReaderSettingsAlerts: CardReaderSettingsAlertsProvider {
    private var modalController: CardPresentPaymentsModalViewController?
    private var severalFoundController: SeveralReadersFoundViewController?

    func scanningForReader(from: UIViewController, cancel: @escaping () -> Void) {
        setViewModelAndPresent(from: from, viewModel: scanningForReader(cancel: cancel))
    }

    func scanningFailed(from: UIViewController, error: Error, close: @escaping () -> Void) {
        setViewModelAndPresent(from: from, viewModel: scanningFailed(error: error, close: close))
    }

    func connectingToReader(from: UIViewController) {
        setViewModelAndPresent(from: from, viewModel: connectingToReader())
    }

    func connectingFailed(from: UIViewController, continueSearch: @escaping () -> Void, cancelSearch: @escaping () -> Void) {
        setViewModelAndPresent(from: from, viewModel: connectingFailed(continueSearch: continueSearch, cancelSearch: cancelSearch))
    }

    func connectingFailedMissingAddress(from: UIViewController,
                                        adminUrl: URL?,
                                        site: Site?,
                                        openUrlInSafari: @escaping (URL) -> Void,
                                        retrySearch: @escaping () -> Void,
                                        cancelSearch: @escaping () -> Void) {
        setViewModelAndPresent(from: from,
                               viewModel: connectingFailedUpdateAddress(adminUrl: adminUrl,
                                                                        site: site,
                                                                        openUrlInSafari: openUrlInSafari,
                                                                        retrySearch: retrySearch,
                                                                        cancelSearch: cancelSearch))
    }

    func connectingFailedInvalidPostalCode(from: UIViewController, retrySearch: @escaping () -> Void, cancelSearch: @escaping () -> Void) {
        setViewModelAndPresent(from: from, viewModel: connectingFailedUpdatePostalCode(retrySearch: retrySearch, cancelSearch: cancelSearch))
    }

    func updatingFailedLowBattery(from: UIViewController, batteryLevel: Double?, close: @escaping () -> Void) {
        setViewModelAndPresent(from: from, viewModel: updatingFailedLowBattery(from: from, batteryLevel: batteryLevel, close: close))
    }

    func updatingFailed(from: UIViewController, tryAgain: (() -> Void)?, close: @escaping () -> Void) {
        setViewModelAndPresent(from: from, viewModel: updatingFailed(from: from, tryAgain: tryAgain, close: close))
    }

    func foundReader(from: UIViewController,
                     name: String,
                     connect: @escaping () -> Void,
                     continueSearch: @escaping () -> Void) {
        setViewModelAndPresent(from: from,
                               viewModel: foundReader(name: name,
                                                      connect: connect,
                                                      continueSearch: continueSearch
                               )
        )
    }

    /// Note: `foundSeveralReaders` uses a view controller distinct from the common
    /// `CardPresentPaymentsModalViewController` to avoid further
    /// overloading `CardPresentPaymentsModalViewModel`
    ///
    /// This will dismiss any view controllers using the common view model first before
    /// presenting the several readers found modal
    ///
    func foundSeveralReaders(from: UIViewController,
                             readerIDs: [String],
                             connect: @escaping (String) -> Void,
                             cancelSearch: @escaping () -> Void) {
        severalFoundController = SeveralReadersFoundViewController()
        severalFoundController?.configureController(
            readerIDs: readerIDs,
            connect: connect,
            cancelSearch: cancelSearch
        )

        dismissCommonAndPresent(animated: false, from: from, present: severalFoundController)
    }

    /// Used to update the readers list in the several readers found view
    ///
    func updateSeveralReadersList(readerIDs: [String]) {
        severalFoundController?.updateReaderIDs(readerIDs: readerIDs)
    }

    /// Shows progress when a software update is being installed
    ///
    func updateProgress(from: UIViewController, requiredUpdate: Bool, progress: Float, cancel: (() -> Void)?) {
        setViewModelAndPresent(
            from: from,
            viewModel: CardPresentModalUpdateProgress(
                requiredUpdate: requiredUpdate,
                progress: progress,
                cancel: cancel
            )
        )
    }

    func dismiss() {
        dismissCommonAndPresent(animated: true)
        dismissSeveralFoundAndPresent(animated: true)
    }
}

private extension CardReaderSettingsAlerts {
    /// Dismisses any view controller based on `CardPresentPaymentsModalViewController`,
    /// then presents any `SeveralReadersFoundViewController` passed to it
    ///
    func dismissCommonAndPresent(animated: Bool = true, from: UIViewController? = nil, present: SeveralReadersFoundViewController? = nil) {
        /// Dismiss any common modal
        ///
        guard modalController == nil else {
            modalController?.dismiss(animated: false, completion: { [weak self] in
                self?.modalController = nil
                guard let from = from, let present = present else {
                    return
                }
                from.present(present, animated: false)
            })
            return
        }

        /// Or, if there was no common modal to dismiss, present straight-away
        ///
        guard let from = from, let present = present else {
            return
        }
        from.present(present, animated: animated)
    }

    /// Dismisses the `SeveralReadersFoundViewController`, then presents any
    /// `CardPresentPaymentsModalViewController` passed to it.
    ///
    func dismissSeveralFoundAndPresent(animated: Bool = true, from: UIViewController? = nil, present: CardPresentPaymentsModalViewController? = nil) {
        guard severalFoundController == nil else {
            severalFoundController?.dismiss(animated: false, completion: { [weak self] in
                self?.severalFoundController = nil
                guard let from = from, let present = present else {
                    return
                }
                from.present(present, animated: false)
            })
            return
        }
        /// Or, if there was no several-found modal to dismiss, present straight-away
        ///
        guard let from = from, let present = present else {
            return
        }
        from.present(present, animated: animated)
    }

    func scanningForReader(cancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalScanningForReader(cancel: cancel)
    }

    func scanningFailed(error: Error, close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        switch error {
        case CardReaderServiceError.bluetoothDenied:
            return CardPresentModalBluetoothRequired(error: error, primaryAction: close)
        default:
            return CardPresentModalScanningFailed(error: error, primaryAction: close)
        }
    }

    func connectingToReader() -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingToReader()
    }

    func connectingFailed(continueSearch: @escaping () -> Void, cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingFailed(continueSearch: continueSearch, cancelSearch: cancelSearch)
    }

    func connectingFailedUpdateAddress(adminUrl: URL?,
                                       site: Site?,
                                       openUrlInSafari: @escaping (URL) -> Void,
                                       retrySearch: @escaping () -> Void,
                                       cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        return CardPresentModalConnectingFailedUpdateAddress(adminUrl: adminUrl,
                                                             site: site,
                                                             openUrlInSafari: openUrlInSafari,
                                                             retrySearch: retrySearch,
                                                             cancelSearch: cancelSearch)
    }

    func connectingFailedUpdatePostalCode(retrySearch: @escaping () -> Void,
                                          cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        return CardPresentModalConnectingFailedUpdatePostalCode(retrySearch: retrySearch, cancelSearch: cancelSearch)
    }

    func updatingFailedLowBattery(from: UIViewController, batteryLevel: Double?, close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalUpdateFailedLowBattery(batteryLevel: batteryLevel, close: close)
    }

    func updatingFailed(from: UIViewController, tryAgain: (() -> Void)?, close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        if let tryAgain = tryAgain {
            return CardPresentModalUpdateFailed(tryAgain: tryAgain, close: close)
        } else {
            return CardPresentModalUpdateFailedNonRetryable(close: close)
        }
    }

    func foundReader(name: String, connect: @escaping () -> Void, continueSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalFoundReader(name: name, connect: connect, continueSearch: continueSearch)
    }

    func setViewModelAndPresent(from: UIViewController, viewModel: CardPresentPaymentsModalViewModel) {
        guard modalController == nil else {
            modalController?.setViewModel(viewModel)
            return
        }

        modalController = CardPresentPaymentsModalViewController(viewModel: viewModel)
        guard let modalController = modalController else {
            return
        }

        modalController.modalPresentationStyle = .custom
        modalController.transitioningDelegate = AppDelegate.shared.tabBarController

        dismissSeveralFoundAndPresent(animated: false, from: from, present: modalController)
    }
}
