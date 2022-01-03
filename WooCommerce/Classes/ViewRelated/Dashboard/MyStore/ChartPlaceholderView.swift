import Foundation
import UIKit


// ChartPlaceholderView: Charts Mockup UI!
//
final class ChartPlaceholderView: UIView {

    /// Top Container View
    ///
    @IBOutlet private var topStackView: UIStackView!

    /// Lines Container View
    ///
    @IBOutlet private var linesStackView: UIStackView!

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
        configureLinesStackView()
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

    /// Chart lines always show the same color without ghost animation.
    func configureLinesStackView() {
        linesStackView.isGhostableDisabled = true
        linesStackView.arrangedSubviews.forEach { chartLineView in
            chartLineView.backgroundColor = .init(light: .gray(.shade5), dark: .systemGray5)
        }
    }
}
