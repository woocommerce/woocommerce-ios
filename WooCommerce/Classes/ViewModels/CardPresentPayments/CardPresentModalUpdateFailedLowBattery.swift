import UIKit

final class CardPresentModalUpdateFailedLowBattery: CardPresentPaymentsModalViewModel {
    private let close: () -> Void
    private let retrySearch: () -> Void

    let textMode: PaymentsModalTextMode = .reducedTopInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = Localization.title

    var topSubtitle: String? = nil

    let image: UIImage = .cardReaderLowBattery

    let primaryButtonTitle: String? = Localization.retry

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String?

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return topTitle
    }

    init(batteryLevel: Double?, retrySearch: @escaping () -> Void, close: @escaping () -> Void) {
        self.retrySearch = retrySearch
        self.close = close
        if let batteryLevel {
            bottomTitle = String(format: Localization.message, 100 * batteryLevel)
        } else {
            bottomTitle = Localization.messageNoBatteryLevel
        }
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        retrySearch()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        close()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }

}

private extension CardPresentModalUpdateFailedLowBattery {
    enum Localization {
        static let title = NSLocalizedString(
            "Please charge reader",
            comment: "Title of the alert presented when an update fails because the reader is low on battery."
        )

        static let message = NSLocalizedString(
            "Updating the reader software failed because the reader’s battery is %.0f%% charged. Please charge the reader above 50%% before trying again.",
            comment: "Button to dismiss the alert presented when an update fails because the reader is low on battery. " +
                "Please leave the %.0f%% intact, as it represents the current percentage of charge."
        )

        static let messageNoBatteryLevel = NSLocalizedString(
            "Updating the reader software failed because the reader is low on battery. Please charge the reader above 50% before trying again.",
            comment: "Button to dismiss the alert presented when an update fails because the reader is low on battery."
        )

        static let retry = NSLocalizedString(
            "cardPresent.modal.updateFailed.lowBattery.retry.button.title",
            value: "Try again",
            comment: "Button title to retry the card reader software update when the reader is low on battery."
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to dismiss the alert presented whenan update fails because the reader is low on battery."
        )
    }
}
