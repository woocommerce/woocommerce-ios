import UIKit
import Yosemite

final class CardPresentModalSelectSearchType: CardPresentPaymentsModalViewModel {
    var textMode: PaymentsModalTextMode

    var actionsMode: PaymentsModalActionsMode

    var topTitle: String = "Select reader type"

    var topSubtitle: String? = nil

    var image: UIImage = .paymentsLoading

    var primaryButtonTitle: String?

    var secondaryButtonTitle: String?

    var auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? = "Your iPhone can be used as a card reader, or you can connect to an external reader via bluetooth"

    var bottomSubtitle: String? = nil

    var accessibilityLabel: String? = nil

    var tapOnIphoneAction: (() -> Void)

    var bluetoothProximityAction: (() -> Void)

    func didTapPrimaryButton(in viewController: UIViewController?) {
        tapOnIphoneAction()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        bluetoothProximityAction()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        //no-op
    }

    init(options: [CardReaderDiscoveryMethod: (() -> Void)]) {
        textMode = .fullInfo
        guard let tapOnIphone = options[.localMobile],
        let bluetooth = options[.bluetoothProximity]
        else {
            actionsMode = .none
            primaryButtonTitle = nil
            tapOnIphoneAction = {}
            secondaryButtonTitle = nil
            bluetoothProximityAction = {}
            return
        }
        actionsMode = .twoAction
        primaryButtonTitle = CardReaderDiscoveryMethod.localMobile.name
        tapOnIphoneAction = tapOnIphone
        secondaryButtonTitle = CardReaderDiscoveryMethod.bluetoothProximity.name
        bluetoothProximityAction = bluetooth
    }
}

private extension CardReaderDiscoveryMethod {
    var name: String {
        switch self {
        case .bluetoothProximity:
            return "Bluetooth reader"
        case .localMobile:
            return "Tap to Pay on iPhone"
        }
    }
}
