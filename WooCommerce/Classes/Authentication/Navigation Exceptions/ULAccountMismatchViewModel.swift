import UIKit

/// Abstracts different configurations and logic related to user interaction
/// for error view controllers presented as part of the Unified Login flow
protocol ULAccountMismatchViewModel {
    /// The logged in user's email
    var userEmail: String { get }

    /// The logged in user's username
    var userName: String { get }

    /// Text pointing out the logged in user's username
    var signedInText: String { get }

    /// Text offering log out
    var logOutTitle: String { get }

    /// An illustration accompanying the error
    var image: UIImage { get }

    /// Extended description of the error.
    var text: NSAttributedString { get }

    /// Provides the title for an auxiliary button
    var auxiliaryButtonTitle: String { get }

    /// Provides a title for a primary action button
    var primaryButtonTitle: String { get }

    /// Provides the title for the logout button
    var logOutButtonTitle: String { get }

    /// Executes action associated to a tap in the view controller log out button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapLogOutButton(in viewController: UIViewController?)

    /// Executes action associated to a tap in the view controller primary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapPrimaryButton(in viewController: UIViewController?)

    /// Executes action associated to a tap in the view controller auxiliary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapAuxiliaryButton(in viewController: UIViewController?)
}
