import UIKit

protocol CardPresentPaymentsModalViewModel {
    /// The title at the top of the modal view. It usually reads as
    var topTitle: String { get }

    /// The second line of text of the modal view. Right over the image
    var topSubtitle: String { get }

    /// An illustration accompanying the modal
    var image: UIImage { get }

    /// Indicates wheter action buttons are visible.
    var areButtonsVisible: Bool { get }

    /// Provides a title for a primary action button
    var primaryButtonTitle: String { get }

    /// Provides a title for a secondary action button
    var secondaryButtonTitle: String { get }

    /// Indicates wheter an auxiliary button is visible
    var isAuxiliaryButtonHidden: Bool { get }

    /// Provides the title for an auxiliary button
    var auxiliaryButtonTitle: String { get }

    /// The title in the bottom section of the modal. Right below the image
    var bottomTitle: String { get }

    /// The subtitle in the bottom section of the modal. Right below the image
    var bottomSubtitle: String { get }

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
