import UIKit

/// Modal presented when we find a reader we can connect to
///
final class CardPresentModalFoundReader: CardPresentPaymentsModalViewModel {
    /// Called when connect button is tapped
    private let connectAction: () -> Void

    /// Called when keep searching button is tapped
    private let continueSearchAction: () -> Void

    let textMode: PaymentsModalTextMode = .noBottomInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    var topTitle: String

    var topSubtitle: String?

    let image: UIImage = .cardReaderFound

    let primaryButtonTitle: String? = Localization.connect

    let secondaryButtonTitle: String? = Localization.continueSearching

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String? = nil

    var bottomSubtitle: String?

    var accessibilityLabel: String? {
        return Localization.connect
    }

    init(name: String, connect: @escaping () -> Void, continueSearch: @escaping () -> Void) {
        self.topTitle = String.localizedStringWithFormat(Localization.title, name)
        self.connectAction = connect
        self.continueSearchAction = continueSearch
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        connectAction()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        continueSearchAction()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {}
}

private extension CardPresentModalFoundReader {
    enum Localization {
        static let title = NSLocalizedString(
            "Do you want to connect to reader %1$@?",
            comment: "Dialog title that displays the name of a found card reader"
        )

        static let connect = NSLocalizedString(
            "Connect to Reader",
            comment: "Label for a button that when tapped, starts the process of connecting to a card reader"
        )

        static let continueSearching = NSLocalizedString(
            "Keep Searching",
            comment: "Label for a button that when tapped, continues searching for card readers"
        )
    }
}
