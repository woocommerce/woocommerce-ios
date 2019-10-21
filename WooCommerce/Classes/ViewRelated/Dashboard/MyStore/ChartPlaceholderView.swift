import Foundation
import UIKit

// ChartPlaceholderView: Charts Mockup UI!
//
class ChartPlaceholderView: UIView {

    /// Top Container View
    ///
    @IBOutlet private var topStackView: UIStackView!

    /// Bars Container View
    ///
    @IBOutlet private var barsStackView: UIStackView!

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        setupSubviews()
    }
}


// MARK: - Private Methods
//
extension ChartPlaceholderView {

    /// Applies Rounded Style to the upper views.
    ///
    fileprivate func setupSubviews() {
        let subviews = barsStackView.subviews + topStackView.subviews.compactMap { $0.subviews.first }
        for view in subviews {
            view.layer.cornerRadius = Settings.cornerRadius
            view.layer.masksToBounds = true
        }
    }
}


// MARK: - Private Types
//
private enum Settings {
    static let cornerRadius = CGFloat(6)
}
