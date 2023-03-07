import UIKit
import Yosemite

final class CardPresentModalSelectSearchType: CardPresentPaymentsModalViewModel {
    var textMode: PaymentsModalTextMode

    var actionsMode: PaymentsModalActionsMode

    var topTitle: String = Localization.title

    var topSubtitle: String? = nil

    var image: UIImage = .cardPaymentsSelectReaderType

    var primaryButtonTitle: String?

    var secondaryButtonTitle: String?

    var auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? = Localization.description

    var bottomSubtitle: String? = nil

    var accessibilityLabel: String? = nil

    private var tapOnIphoneAction: (() -> Void)

    private var bluetoothScanAction: (() -> Void)

    private var cancelAction: (() -> Void)

    func didTapPrimaryButton(in viewController: UIViewController?) {
        tapOnIphoneAction()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        bluetoothScanAction()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        cancelAction()
    }

    init(tapOnIPhoneAction: @escaping () -> Void,
         bluetoothAction: @escaping () -> Void,
         cancelAction: @escaping () -> Void) {
        textMode = .fullInfo
        actionsMode = .twoActionAndAuxiliary
        primaryButtonTitle = CardReaderDiscoveryMethod.localMobile.name
        self.tapOnIphoneAction = tapOnIPhoneAction
        secondaryButtonTitle = CardReaderDiscoveryMethod.bluetoothScan.name
        self.bluetoothScanAction = bluetoothAction
        auxiliaryButtonTitle = Localization.cancel
        self.cancelAction = cancelAction
    }
}

private extension CardPresentModalSelectSearchType {
    enum Localization {
        static let title = NSLocalizedString(
            "Select reader type",
            comment: "The title for the alert shown when connecting a card reader, asking the user to choose a " +
            "reader type. Only shown when supported on their device.")

        static let description = NSLocalizedString(
            "Your iPhone can be used as a card reader, or you can connect to an external reader via Bluetooth.",
            comment: "The description on the alert shown when connecting a card reader, asking the user to choose a " +
            "reader type. Only shown when supported on their device.")

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Cancel button title")
    }
}

private extension CardReaderDiscoveryMethod {
    var name: String {
        switch self {
        case .bluetoothScan:
            return NSLocalizedString(
                "Bluetooth Reader",
                comment: "The button title on the reader type alert, for the user to choose a bluetooth reader.")
        case .localMobile:
            return NSLocalizedString(
                "Tap to Pay on iPhone",
                comment: "The button title on the reader type alert, for the user to choose the built-in reader.")
        }
    }
}
