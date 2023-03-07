import UIKit
import Combine

/// Abstracts different configurations and logic related to user interaction
/// for error view controllers presented as part of the Unified Login flow
protocol ULErrorViewModel {
    /// A title for the error screen
    var title: String? { get }

    /// An illustration accompanying the error
    var image: UIImage { get }

    /// Extended description of the error.
    var text: NSAttributedString { get }

    /// Indicates whether the auxiliary button is visible
    var isAuxiliaryButtonHidden: Bool { get }

    /// Provides the title for an auxiliary button
    var auxiliaryButtonTitle: String { get }

    /// Provides a title for a primary action button
    var primaryButtonTitle: String { get }

    /// Indicates whether the primary button is visible
    var isPrimaryButtonHidden: Bool { get }

    /// Indicates whether the primary button is showing the loading indicator
    var isPrimaryButtonLoading: AnyPublisher<Bool, Never> { get }

    /// Provides a title for a secondary action button
    var secondaryButtonTitle: String { get }

    /// Indicates whether the secondary button is visible
    var isSecondaryButtonHidden: Bool { get }

    /// Additional view to the bottom of the vertical stack view that contains the image, text, and auxiliary button.
    var auxiliaryView: UIView? { get }

    /// A text explaining the terms when the primary button is tapped.
    ///
    var termsLabelText: NSAttributedString? { get }

    /// Indicates whether the site address view should be hidden.
    ///
    var isSiteAddressViewHidden: Bool { get }

    /// Address of the site.
    ///
    var siteURL: String { get }

    /// Favicon of the site with error.
    ///
    var siteFavicon: AnyPublisher<UIImage?, Never> { get }

    /// Executed by the view controller when its view was loaded.
    /// - Parameter viewController: the view controller that loads the view.
    func viewDidLoad(_ viewController: UIViewController?)

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

// MARK: Default implementation for optional variables
extension ULErrorViewModel {
    var title: String? { nil }

    var isPrimaryButtonHidden: Bool { false }

    var isPrimaryButtonLoading: AnyPublisher<Bool, Never> { Just(false).eraseToAnyPublisher() }

    var isSecondaryButtonHidden: Bool { false }

    var auxiliaryView: UIView? { nil }

    var isSiteAddressViewHidden: Bool { true }

    var siteURL: String { "" }

    var siteFavicon: AnyPublisher<UIImage?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
}

// MARK: Default implementation for optional right bar button item
//
extension ULErrorViewModel {
    var rightBarButtonItemTitle: String? { nil }

    var termsLabelText: NSAttributedString? { nil }

    func didTapRightBarButtonItem(in viewController: UIViewController?) {
        // NO-OP
    }
}
