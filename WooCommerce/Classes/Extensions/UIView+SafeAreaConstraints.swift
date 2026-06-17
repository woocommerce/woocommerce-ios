import UIKit

extension UIView {
    var safeLeadingAnchor: NSLayoutAnchor<NSLayoutXAxisAnchor> {
        get {
            safeAreaLayoutGuide.leadingAnchor
        }
    }
    var safeTrailingAnchor: NSLayoutAnchor<NSLayoutXAxisAnchor> {
        get {
            safeAreaLayoutGuide.trailingAnchor
        }
    }
    var safeLeftAnchor: NSLayoutAnchor<NSLayoutXAxisAnchor> {
        get {
            safeAreaLayoutGuide.leftAnchor
        }
    }
    var safeRightAnchor: NSLayoutAnchor<NSLayoutXAxisAnchor> {
        get {
            safeAreaLayoutGuide.rightAnchor
        }
    }
    var safeTopAnchor: NSLayoutAnchor<NSLayoutYAxisAnchor> {
        get {
            safeAreaLayoutGuide.topAnchor
        }
    }
    var safeBottomAnchor: NSLayoutAnchor<NSLayoutYAxisAnchor> {
        get {
            safeAreaLayoutGuide.bottomAnchor
        }
    }

    func pinSubviewBottomToBottomAnchorReplacingSafeArea(_ subview: UIView) {
        let constraintsToDeactivate = constraints.filter { constraint in
            guard constraint.firstAttribute == .bottom,
                  constraint.secondAttribute == .bottom else {
                return false
            }

            let isSubviewConstrainedToSafeArea = (constraint.firstItem as? UIView) === subview &&
                (constraint.secondItem as? UILayoutGuide) === safeAreaLayoutGuide
            let isSafeAreaConstrainedToSubview = (constraint.firstItem as? UILayoutGuide) === safeAreaLayoutGuide &&
                (constraint.secondItem as? UIView) === subview

            return isSubviewConstrainedToSafeArea || isSafeAreaConstrainedToSubview
        }

        guard !constraintsToDeactivate.isEmpty else {
            return
        }

        NSLayoutConstraint.deactivate(constraintsToDeactivate)
        subview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}
