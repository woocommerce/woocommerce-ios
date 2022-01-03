import Foundation
import UIKit


// ChartPlaceholderView: Charts Mockup UI!
//
final class ChartPlaceholderView: UIView {

    /// Top Container View
    ///
    @IBOutlet private var topStackView: UIStackView!

    /// Bars Container View
    ///
    @IBOutlet private var barsStackView: UIStackView!

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
        configureBarsStackView()
    }
}


// MARK: - Private Methods
//
private extension ChartPlaceholderView {
    /// Applies color to the view.
    ///
    func configureView() {
        backgroundColor = .listForeground
        topStackView.backgroundColor = .listForeground
    }

    func configureBarsStackView() {
        barsStackView.isGhostableDisabled = true
        barsStackView.arrangedSubviews.forEach { chartLineView in
            chartLineView.backgroundColor = .init(light: .gray(.shade5), dark: .systemGray5)
        }
    }
}
