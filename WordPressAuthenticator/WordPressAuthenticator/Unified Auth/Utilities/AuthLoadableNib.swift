import UIKit


/// AuthLoadableNib: A protocol for views that can be loaded from nibs in the Authenticator project.
/// Borrowed from NibLoadable protocol in WordPress-iOS.
///
public protocol AuthLoadableNib {

    /// Default nib name.
    static var defaultNibName: String { get }

    /// Default bundle to load from.
    static var defaultBundle: Bundle { get }

    /// The UITableViewCell reuseIdentifier
    static var reuseIdentifier: String { get }
}


public extension AuthLoadableNib {

    static var defaultNibName: String {
        return String(describing: self)
    }

    static var defaultBundle: Bundle {
        return WordPressAuthenticator.bundle
    }

    static var reuseIdentifier: String {
        return String(describing: self)
    }

    /// Loads the default nib.
    ///
    /// - Returns: the loaded nib.
    static func loadNib() -> UINib {
        return UINib(nibName: defaultNibName, bundle: defaultBundle)
    }
}
