import UIKit

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

    /// Provides a title for a secondary action button
    var secondaryButtonTitle: String { get }

    /// Indicates whether the secondary button is visible
    var isSecondaryButtonHidden: Bool { get }

    /// Additional view to the bottom of the vertical stack view that contains the image, text, and auxiliary button.
    var auxiliaryView: UIView? { get }

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
}

// MARK: - Default implementation for optional variables
extension ULErrorViewModel {
    var title: String? { nil }

    var isPrimaryButtonHidden: Bool { false }

    var isSecondaryButtonHidden: Bool { false }

    var auxiliaryView: UIView? { nil }
}
