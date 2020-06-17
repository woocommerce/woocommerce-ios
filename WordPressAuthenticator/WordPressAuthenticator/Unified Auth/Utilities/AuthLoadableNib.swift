import UIKit


/// AuthLoadableNib: A protocol for views that can be loaded from nibs in the Authenticator project.
/// Borrowed from NibLoadable protocol in WordPress-iOS.
///
public protocol AuthLoadableNib {

    /// Default nib name.
    static var defaultNibName: String { get }

    /// Default bundle to load from.
    static var defaultBundle: Bundle { get }

    /// Default nib created using nib name and bundle.
    static var defaultNib: UINib { get }
}


public extension AuthLoadableNib {

    static var defaultNibName: String {
        return String(describing: self)
    }

    static var defaultBundle: Bundle {
        return WordPressAuthenticator.bundle
    }

    static var defaultNib: UINib {
        return UINib(nibName: defaultNibName, bundle: defaultBundle)
    }

    /// Loads view from the default nib.
    ///
    /// - Returns: Loaded view.
    static func loadNib() -> Self {
        guard let result = defaultBundle.loadNibNamed(defaultNibName, owner: nil, options: nil)?.first as? Self else {
            fatalError("[NibLoadable] Cannot load view from nib.")
        }

        return result
    }
}
