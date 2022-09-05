import UIKit

/// Abstracts configuration and contents of the modal screens presented
/// during operations related to Card Present Payments
protocol CardPresentPaymentsModalViewModel {
    /// The number and distribution of text labels
    var textMode: PaymentsModalTextMode { get }

    /// The number and distribution of action buttons
    var actionsMode: PaymentsModalActionsMode { get }

    /// The title at the top of the modal view.
    var topTitle: String { get }

    /// The second line of text of the modal view. Right over the illustration
    var topSubtitle: String? { get }

    /// An illustration accompanying the modal
    var image: UIImage { get }

    /// Provides a title for a primary action button
    var primaryButtonTitle: String? { get }

    /// Provides a title for a secondary action button
    var secondaryButtonTitle: String? { get }

    /// Provides a title for an auxiliary button
    var auxiliaryButtonTitle: String? { get }

    /// Provides a title as a NSAttributedString for an auxiliary button
    var auxiliaryAttributedButtonTitle: NSAttributedString? { get }

    /// Provides an image for the auxiliary button
    var auxiliaryButtonimage: UIImage? { get }

    /// The title in the bottom section of the modal. Right below the image
    var bottomTitle: String? { get }

    /// The subtitle in the bottom section of the modal. Right below the image
    var bottomSubtitle: String? { get }

    /// The accessibilityLabel to be provided to VoiceOver
    var accessibilityLabel: String? { get }

    /// Executes action associated to a tap in the view controller primary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapPrimaryButton(in viewController: UIViewController?)

    /// Executes action associated to a tap in the view controller secondary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapSecondaryButton(in viewController: UIViewController?)

    /// Executes action associated to a tap in the view controller auxiliary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapAuxiliaryButton(in viewController: UIViewController?)
}

/// The type of card-present transaction.
enum CardPresentTransactionType {
    /// To collect payment.
    case collectPayment

    /// To issue a refund.
    case refund
}

/// Represents the different visual modes of the modal view's textfields
enum PaymentsModalTextMode {
    /// From top to bottom: Two lines of text at the top, image, two more lines of text
    case fullInfo

    /// From top to bottom: One line of text at the top, image
    case reducedTopInfo

    /// From top to bottom: Two lines of text at the top, image, one more line of text
    case reducedBottomInfo

    /// From top to bottom: Two lines of text at the top, and image
    case noBottomInfo
}

enum PaymentsModalActionsMode {
    /// No action buttons
    case none

    /// One action button
    case oneAction

    /// One secondary action button
    case secondaryOnlyAction

    /// One secondary action button and an auxiliary button
    case secondaryActionAndAuxiliaryButton

    /// Two action buttons
    case twoAction

    /// Two action buttons and an auxiliary button
    case twoActionAndAuxiliary

}

extension CardPresentPaymentsModalViewModel {
    /// Default implementation for NSAttributedString auxiliary button title.
    /// If is not set directly by each Modal's ViewModel, it will default to nil
    var auxiliaryAttributedButtonTitle: NSAttributedString? {
        get { return nil }
    }

    var auxiliaryButtonimage: UIImage? {
        get { return nil }
    }
}
