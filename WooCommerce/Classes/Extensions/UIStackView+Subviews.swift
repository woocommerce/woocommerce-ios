import UIKit

extension UIStackView {
    /// Removes all the arranged subviews in the stack view.
    ///
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach(removeArrangedSubview(_:))
    }

    /// Adds an array of arranged subviews to the stack view.
    ///
    func addArrangedSubviews(_ subviews: [UIView]) {
        subviews.forEach({ addArrangedSubview($0) })
    }
}
