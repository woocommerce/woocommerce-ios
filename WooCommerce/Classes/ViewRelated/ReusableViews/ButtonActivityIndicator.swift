import UIKit

/// Displays a button with an activity indicator in the center
///
final class ButtonActivityIndicator: UIButton {

    let indicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)

    override func layoutSubviews() {
        super.layoutSubviews()

        if indicator.isAnimating {
            var frm = indicator.frame
            frm.origin.x = (frame.width - frm.width) / 2.0
            frm.origin.y = (frame.height - frm.height) / 2.0
            indicator.frame = frm.integral
        }

        titleLabel?.isHidden = indicator.isAnimating
    }

    /// Display the loader indicator inside the button
    ///
    func showActivityIndicator() {
        guard subviews.contains(indicator) == false else {
            return
        }
        titleLabel?.isHidden = true
        indicator.isUserInteractionEnabled = false
        indicator.center = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
        indicator.hidesWhenStopped = true
        // If `hideActivityIndicator()` is called immediately after this method, it will find the indicator and remove it
        addSubview(indicator)
        indicator.startAnimating()
    }

    /// Hide the loader indicator inside the button
    ///
    func hideActivityIndicator() {
        guard subviews.contains(indicator) == true else {
            return
        }
        indicator.stopAnimating()
        indicator.removeFromSuperview()
        titleLabel?.isHidden = false
    }
}

private extension ButtonActivityIndicator {
    enum Constants {
        static let animationDuration = 0.3
    }
}
