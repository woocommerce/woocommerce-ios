import UIKit
import Yosemite

/// Modal presented under the Apple-provided built in reader modal, while the card is being collected.
/// This may be visible for a moment or two either side of Apple's screen being shown.
final class CardPresentModalBuiltInFollowReaderInstructions: CardPresentPaymentsModalViewModel {

    /// Customer name
    private let name: String

    /// Charge amount
    private let amount: String

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .none

    var topTitle: String {
        name
    }

    var topSubtitle: String? {
        amount
    }

    let image: UIImage = .preparingBuiltInReader

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String? = Localization.readerIsReady

    let bottomSubtitle: String?

    let accessibilityLabel: String?

    init(name: String,
         amount: String,
         transactionType: CardPresentTransactionType,
         inputMethods: CardReaderInput) {
        self.name = name
        self.amount = amount

        self.bottomSubtitle = Localization.followReaderInstructions

        self.accessibilityLabel = Localization.readerIsReady + Localization.followReaderInstructions
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        //
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        //
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        //
    }
}

private extension CardPresentModalBuiltInFollowReaderInstructions {
    enum Localization {
        static let readerIsReady = NSLocalizedString(
            "Tap to Pay on iPhone is ready",
            comment: "Indicates the status of Tap to Pay on iPhone collection readiness. Presented to users when payment collection starts"
        )

        static let followReaderInstructions = NSLocalizedString(
            "Follow the on-screen instructions to pay",
            comment: "Label asking users to follow the on-screen Tap to Pay on iPhone instructions. Presented when " +
            "a payment is going to be collected using Tap to Pay on iPhone, which results in an Apple-provided " +
            "screen being shown with instructions for payment."
        )
    }
}
