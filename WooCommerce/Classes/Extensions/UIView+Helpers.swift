import Foundation
import UIKit


/// UIView Helper Methods
///
extension UIView {

    /// Returns the first Object contained within the nib with a name whose name matches with the receiver's type.
    /// Note: On error this method is expected to break, by design!
    ///
    class func loadFromNib<T>() -> T {
        let nib = UINib(nibName: classNameWithoutNamespaces, bundle: nil)
        return nib.instantiate(withOwner: nil, options: nil).first as! T
    }
}
