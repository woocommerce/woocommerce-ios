import UIKit

/// UIView class methods
///
extension UIView {
    /// Returns the Nib associated with the received: It's filename is expected to match the Class Name
    ///
    class func loadNib() -> UINib {
        return UINib(nibName: classNameWithoutNamespaces, bundle: WordPressAuthenticator.bundle)
    }
}
