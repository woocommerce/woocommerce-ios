import UIKit
import WordPressUI

/// A layer of indirection between our card reader settings view controllers and the modal alerts
/// presented to provide user-facing feedback as we discover, connect and manage card readers
///
final class CardReaderSettingsAlerts {
    private var modalController: CardPresentPaymentsModalViewController?

    func scanningForReader(from: UIViewController, cancel: @escaping () -> Void) {
        let viewModel = scanningForReader(cancel: cancel)
        let newAlert = CardPresentPaymentsModalViewController(viewModel: viewModel)
        modalController = newAlert
        modalController?.modalPresentationStyle = .custom
        modalController?.transitioningDelegate = AppDelegate.shared.tabBarController
        from.present(newAlert, animated: true)
    }

    func connectingToReader(from: UIViewController) {
        let viewModel = connectingToReader()
        let newAlert = CardPresentPaymentsModalViewController(viewModel: viewModel)
        modalController = newAlert
        modalController?.modalPresentationStyle = .custom
        modalController?.transitioningDelegate = AppDelegate.shared.tabBarController
        from.present(newAlert, animated: true)
    }

    func foundReader(from: UIViewController, name: String, connect: @escaping () -> Void, continueSearch: @escaping () -> Void) {
        let viewModel = foundReader(name: name, connect: connect, continueSearch: continueSearch)
        let newAlert = CardPresentPaymentsModalViewController(viewModel: viewModel)
        modalController = newAlert
        modalController?.modalPresentationStyle = .custom
        modalController?.transitioningDelegate = AppDelegate.shared.tabBarController
        from.present(newAlert, animated: true)
    }

    func dismiss() {
        modalController?.dismiss(animated: true, completion: nil)
    }
}

private extension CardReaderSettingsAlerts {
    func scanningForReader(cancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalScanningForReader(cancel: cancel)
    }

    func connectingToReader() -> CardPresentPaymentsModalViewModel {
        CardPresentModalConnectingToReader()
    }

    func foundReader(name: String, connect: @escaping () -> Void, continueSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalFoundReader(name: name, connect: connect, continueSearch: continueSearch)
    }
}
