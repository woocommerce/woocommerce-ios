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
}
