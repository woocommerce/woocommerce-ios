import UIKit

/// Displays a button with an activity indicator in the center
///
final class ButtonActivityIndicator: UIButton {

    private let indicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)

    override func layoutSubviews() {
        super.layoutSubviews()

        if indicator.isAnimating {
            var frm = indicator.frame
            frm.origin.x = (frame.width - frm.width) / 2.0
            frm.origin.y = (frame.height - frm.height) / 2.0
            indicator.frame = frm.integral
        }
    }

    /// Display the loader indicator inside the button
    ///
    func showActivityIndicator() {
        guard subviews.contains(indicator) == false else {
            return
        }
        indicator.isUserInteractionEnabled = false
        indicator.center = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
        UIView.transition(with: self, duration: Constants.animationDuration, options: .curveEaseOut, animations: { [weak self] in
            self?.titleLabel?.alpha = 0.0
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.addSubview(self.indicator)
            self.indicator.startAnimating()
        }
    }

    /// Hide the loader indicator inside the button
    ///
    func hideActivityIndicator() {
        guard subviews.contains(indicator) == true else {
            return
        }
        indicator.stopAnimating()
        indicator.removeFromSuperview()
        UIView.transition(with: self, duration: Constants.animationDuration, options: .curveEaseIn, animations: { [weak self] in
            self?.titleLabel?.alpha = 1.0
        }) { (finished) in
        }
    }
}

private extension ButtonActivityIndicator {
    enum Constants {
        static let animationDuration = 0.3
    }
}
