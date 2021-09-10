import UIKit
import Yosemite
import WordPressUI

/// A layer of indirection between our card reader settings view controllers and the modal alerts
/// presented to provide user-facing feedback as we discover, connect and manage card readers
///
final class CardReaderSettingsAlerts: CardReaderSettingsAlertsProvider {
    private var modalController: CardPresentPaymentsModalViewController?

    func scanningForReader(from: UIViewController, cancel: @escaping () -> Void) {
        setViewModelAndPresent(from: from, viewModel: scanningForReader(cancel: cancel))
    }

    func scanningFailed(from: UIViewController, error: Error, close: @escaping () -> Void) {
        setViewModelAndPresent(from: from, viewModel: scanningFailed(error: error, close: close))
    }

    func connectingToReader(from: UIViewController) {
        setViewModelAndPresent(from: from, viewModel: connectingToReader())
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

    func updateProgress(from: UIViewController, progress: Float, cancel: (() -> Void)?) {
        setViewModelAndPresent(
            from: from,
            viewModel: CardPresentModalUpdateProgress(
                progress: progress,
                cancel: cancel
            )
        )
    }

    func dismiss() {
        modalController?.dismiss(animated: true, completion: { [weak self] in
            self?.modalController = nil
        })
    }
}

private extension CardReaderSettingsAlerts {
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
        from.present(modalController, animated: true)
    }
}
