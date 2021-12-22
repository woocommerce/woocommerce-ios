import UIKit

extension UIView {
    var safeLeadingAnchor: NSLayoutAnchor<NSLayoutXAxisAnchor> {
        get {
            if #available(iOS 11.0, *) {
                return self.safeAreaLayoutGuide.leadingAnchor
            } else {
                return self.leadingAnchor
            }
        }
    }
    var safeTrailingAnchor: NSLayoutAnchor<NSLayoutXAxisAnchor> {
        get {
            if #available(iOS 11.0, *) {
                return self.safeAreaLayoutGuide.trailingAnchor
            } else {
                return self.trailingAnchor
            }
        }
    }
    var safeLeftAnchor: NSLayoutAnchor<NSLayoutXAxisAnchor> {
        get {
            if #available(iOS 11.0, *) {
                return self.safeAreaLayoutGuide.leftAnchor
            } else {
                return self.leftAnchor
            }
        }
    }
    var safeRightAnchor: NSLayoutAnchor<NSLayoutXAxisAnchor> {
        get {
            if #available(iOS 11.0, *) {
                return self.safeAreaLayoutGuide.rightAnchor
            } else {
                return self.rightAnchor
            }
        }
    }
    var safeTopAnchor: NSLayoutAnchor<NSLayoutYAxisAnchor> {
        get {
            if #available(iOS 11.0, *) {
                return self.safeAreaLayoutGuide.topAnchor
            } else {
                return self.topAnchor
            }
        }
    }
    var safeBottomAnchor: NSLayoutAnchor<NSLayoutYAxisAnchor> {
        get {
            if #available(iOS 11.0, *) {
                return self.safeAreaLayoutGuide.bottomAnchor
            } else {
                return self.bottomAnchor
            }
        }
    }
}
