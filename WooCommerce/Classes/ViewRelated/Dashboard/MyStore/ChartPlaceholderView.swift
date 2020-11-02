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
        setupView()
        setupSubviews()
    }
}


// MARK: - Private Methods
//
private extension ChartPlaceholderView {
    /// Applies color to the view.
    ///
    func setupView() {
        backgroundColor = .listForeground
        topStackView.backgroundColor = .listForeground
    }

    /// Applies Rounded Style to the upper views.
    ///
    func setupSubviews() {
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
