import Combine
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

    /// A text explaining the terms when the primary button is tapped.
    ///
    var termsLabelText: AnyPublisher<NSAttributedString, Never> { get }

    /// Provides the title for an auxiliary button
    var auxiliaryButtonTitle: String { get }

    /// Provides a title for a primary action button
    var primaryButtonTitle: String { get }

    /// Provides the loading state of the primary button
    var isPrimaryButtonLoading: AnyPublisher<Bool, Never> { get }

    /// Provides a title for a secondary action button
    var secondaryButtonTitle: String { get }

    /// Provides the visibility of the secondary button
    var isSecondaryButtonHidden: Bool { get }

    /// Provides the title for the logout button
    var logOutButtonTitle: String { get }

    /// Executed by the view controller when its view was loaded.
    /// - Parameter viewController: the view controller that loads the view.
    func viewDidLoad(_ viewController: UIViewController?)

    /// Executes action associated to a tap in the view controller log out button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapLogOutButton(in viewController: UIViewController?)

    /// Executes action associated to a tap in the view controller primary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapPrimaryButton(in viewController: UIViewController?)

    /// Executes action associated to a tap in the view controller secondary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapSecondaryButton(in viewController: UIViewController?)

    /// Executes action associated to a tap in the view controller auxiliary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapAuxiliaryButton(in viewController: UIViewController?)

    // MARK: Navigation bar - right bar button item
    //

    /// Title of the right bar button item in the navigation bar
    ///  return `nil` if you don't want a `rightBarButtonItem`
    ///
    var rightBarButtonItemTitle: String? { get }

    /// Executes action associated to a tap on the right bar button item in the navigation bar
    /// - Parameter viewController: usually the view controller sending the tap
    ///
    func didTapRightBarButtonItem(in viewController: UIViewController?)
}

// MARK: Default implementation for optional right bar button item
//
extension ULAccountMismatchViewModel {
    var rightBarButtonItemTitle: String? { nil }

    func didTapRightBarButtonItem(in viewController: UIViewController?) {
        // NO-OP
    }
}
