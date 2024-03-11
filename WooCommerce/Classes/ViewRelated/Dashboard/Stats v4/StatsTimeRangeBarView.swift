import UIKit
import Experiments

/// Contains a label that displays the time range - a date, date range for a week, month, or year.
final class StatsTimeRangeBarView: UIView {
    // MARK: Subviews
    private let button = UIButton(frame: .zero)

    // To be updated externally to handle button tap
    var editCustomTimeRangeHandler: (() -> Void)?

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        configureButton()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureButton()
    }

    /// Updates the label with start/end dates, time range type, and site time zone.
    func updateUI(viewModel: StatsTimeRangeBarViewModel) {
        button.isEnabled = viewModel.isTimeRangeEditable

        var configuration = UIButton.Configuration.plain()
        configuration.titleAlignment = .center
        configuration.image = viewModel.isTimeRangeEditable ? UIImage(systemName: "calendar") : nil
        configuration.imagePlacement = .leading
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(font: Constants.labelFont)
        configuration.imagePadding = Constants.imagePadding

        var container = AttributeContainer()
        container.font = Constants.labelFont
        container.foregroundColor = viewModel.isTimeRangeEditable ? .accent : Constants.labelColor
        configuration.attributedTitle = AttributedString(viewModel.timeRangeText, attributes: container)

        button.configuration = configuration
    }
}

private extension StatsTimeRangeBarView {
    func configureButton() {
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        pinSubviewToAllEdges(button, insets: Constants.labelInsets)

        button.on(.touchUpInside) { [weak self] _ in
            self?.editCustomTimeRangeHandler?()
        }
    }
}

private extension StatsTimeRangeBarView {
    enum Constants {
        static let labelInsets = UIEdgeInsets(top: 15, left: 16, bottom: 10, right: 16)
        static let labelFont: UIFont = .footnote
        static let labelColor: UIColor = .secondaryLabel
        static let labelTextAlignment: NSTextAlignment = .center
        static let imagePadding: CGFloat = 8
    }
}
