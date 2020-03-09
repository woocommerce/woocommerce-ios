import UIKit

/// Contains a label that displays the time range - a date, date range for a week, month, or year.
class StatsTimeRangeBarView: UIView {
    // MARK: Subviews
    private let label = UILabel(frame: .zero)

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        configureLabel()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureLabel()
    }

    /// Updates the label with start/end dates, time range type, and site time zone.
    func updateUI(viewModel: StatsTimeRangeBarViewModel) {
        label.text = viewModel.timeRangeText
    }
}

private extension StatsTimeRangeBarView {
    func configureLabel() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        pinSubviewToAllEdges(label, insets: Constants.labelInsets)

        label.font = StyleManager.headlineSemiBold
        label.textColor = .text
    }
}

private extension StatsTimeRangeBarView {
    enum Constants {
        static let labelInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }
}
