import Foundation
import WordPressUI


/// This is a subclass of WordPressUI's `FancyButton` that offers a UIActivityIndicatorView
/// for extra spin-y fun!
///
class FancyAnimatedButton: FancyButton {

    @objc var isAnimating: Bool {
        return activityIndicator.isAnimating
    }

    @objc let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .gray
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override open func layoutSubviews() {
        super.layoutSubviews()

        if activityIndicator.isAnimating {
            titleLabel?.frame = CGRect.zero

            var frm = activityIndicator.frame
            frm.origin.x = (frame.width - frm.width) / 2.0
            frm.origin.y = (frame.height - frm.height) / 2.0
            activityIndicator.frame = frm.integral
        }
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        addSubview(activityIndicator)
    }

    /// Toggles the visibility of the activity indicator.  When visible the button
    /// title is hidden.
    ///
    /// - Parameter show: True to show the spinner. False hides it.
    ///
    open func showActivityIndicator(_ show: Bool) {
        if show {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        setNeedsLayout()
    }
}
