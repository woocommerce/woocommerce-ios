import UIKit

protocol CardPresentPaymentsModalViewModel {
    /// An illustration accompanying the modal
    var image: UIImage { get }

    /// Extended description of the error.
    var text: NSAttributedString { get }

    /// Indicates wheter an auxiliary button is visible
    var isAuxiliaryButtonHidden: Bool { get }

    /// Provides the title for an auxiliary button
    var auxiliaryButtonTitle: String { get }

    /// Provides a title for a primary action button
    var primaryButtonTitle: String { get }

    /// Provides a title for a secondary action button
    var secondaryButtonTitle: String { get }

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
