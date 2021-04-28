import UIKit

protocol CardPresentPaymentsModalViewModel {
    /// The visual mode of the modal
    var mode: PaymentsModalMode { get }

    /// The title at the top of the modal view. It usually reads as
    var topTitle: String { get }

    /// The second line of text of the modal view. Right over the image
    var topSubtitle: String? { get }

    /// An illustration accompanying the modal
    var image: UIImage { get }

    /// Provides a title for a primary action button
    var primaryButtonTitle: String? { get }

    /// Provides a title for a secondary action button
    var secondaryButtonTitle: String? { get }

    /// The title in the bottom section of the modal. Right below the image
    var bottomTitle: String? { get }

    /// The subtitle in the bottom section of the modal. Right below the image
    var bottomSubtitle: String? { get }

    /// Executes action associated to a tap in the view controller primary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapPrimaryButton(in viewController: UIViewController?)

    /// Executes action associated to a tap in the view controller secondary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapSecondaryButton(in viewController: UIViewController?)
}


enum PaymentsModalMode {
    /// From top to bottom: Two lines of text at the top, image, two more lines of text
    case fullInfo

    /// From top to bottom: Two lines of text at the top, image, one more line of text
    case reducedInfo

    /// From top to bottom: Two lines of text at the top, image, two action buttons
    case twoActionButtons

    /// From top to bottom: Two lines of text at the top, image, one action button
    case oneActionButton

    /// From top to bottom: One line of text at the top, image, one action button
    case reducedInfoOneActionButton
}
