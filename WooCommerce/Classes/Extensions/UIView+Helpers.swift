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

/// UIView Auto Layout Helpers
///
extension UIView {
    func pinSubviewToSafeArea(_ subview: UIView, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: subview.leadingAnchor, constant: -insets.left),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: insets.right),
            safeAreaLayoutGuide.topAnchor.constraint(equalTo: subview.topAnchor, constant: -insets.top),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: insets.bottom),
            ])
    }

    func pinSubviewToAllEdges(_ subview: UIView, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: subview.leadingAnchor, constant: -insets.left),
            trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: insets.right),
            topAnchor.constraint(equalTo: subview.topAnchor, constant: -insets.top),
            bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: insets.bottom),
            ])
    }
}
