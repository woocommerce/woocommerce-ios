import Foundation
import UIKit


/// UIView Class Methods
///
extension UIView {

    /// Returns the Nib associated with the received: It's filename is expected to match the Class Name
    ///
    class func loadNib() -> UINib {
        return UINib(nibName: classNameWithoutNamespaces, bundle: nil)
    }

    /// Returns the first Object contained within the nib with a name whose name matches with the receiver's type.
    /// Note: On error this method is expected to break, by design!
    ///
    class func instantiateFromNib<T>() -> T {
        return loadNib().instantiate(withOwner: nil, options: nil).first as! T
    }

    /// Returns whether there is a Nib associated with the receiver, being the filename its Class Name.
    /// Use it to avoid *Could not load NIB in bundle* crash before loading it if you are not sure that it exists.
    ///
    class func nibExistsInMainBundle() -> Bool {
        Bundle.main.path(forResource: classNameWithoutNamespaces, ofType: "nib") != nil
    }
}


/// UIView Extension Methods
///
extension UIView {

    /// Returns the first Subview of the specified Type (if any).
    ///
    func firstSubview<T: UIView>(ofType type: T.Type) -> T? {
        for subview in subviews {
            guard let target = (subview as? T) ?? subview.firstSubview(ofType: type) else {
                continue
            }

            return target
        }

        return nil
    }
}
