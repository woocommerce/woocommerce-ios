import UIKit

extension UIView {
    /// Creates a border view with the given height and color.
    /// - Parameter height: height of the border. Default to be 0.5px.
    /// - Parameter color: background color of the border. Default to be the divider color.
    static func createBorderView(height: CGFloat = 0.5,
                                 color: UIColor = .listSmallIcon) -> UIView {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = color
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: height)
            ])
        return view
    }
}
