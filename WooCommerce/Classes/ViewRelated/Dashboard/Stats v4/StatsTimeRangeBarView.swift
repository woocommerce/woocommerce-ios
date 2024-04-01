import UIKit
import Experiments

/// Contains a label that displays the time range - a date, date range for a week, month, or year.
final class StatsTimeRangeBarView: UIView {
    // MARK: Subviews
    private let stackView = UIStackView(frame: .zero)
    private let button = UIButton(frame: .zero)
    private let selectedDateLabel = UILabel(frame: .zero)

    // To be updated externally to handle button tap
    var editCustomTimeRangeHandler: (() -> Void)?

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        configureStackView()
        configureButton()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureStackView()
        configureButton()
        configureSelectedDateLabel()
    }

    /// Updates the label with start/end dates, time range type, and site time zone.
    func updateUI(viewModel: StatsTimeRangeBarViewModel) {
        button.isEnabled = viewModel.isTimeRangeEditable

        var configuration = UIButton.Configuration.plain()
        configuration.titleAlignment = .center
        configuration.image = viewModel.isTimeRangeEditable ? UIImage(systemName: "pencil") : nil
        configuration.imagePlacement = .trailing
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(font: Constants.labelFont)
        configuration.imagePadding = Constants.imagePadding

        var container = AttributeContainer()
        container.font = Constants.labelFont.bold
        container.foregroundColor = viewModel.isTimeRangeEditable ? .accent : Constants.labelColor
        configuration.attributedTitle = AttributedString(viewModel.timeRangeText, attributes: container)

        selectedDateLabel.text = viewModel.selectedDateText

        button.configuration = configuration
    }
}

private extension StatsTimeRangeBarView {
    func configureStackView() {
        addSubview(stackView)
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = Constants.stackViewSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(stackView, insets: Constants.stackViewInset)
    }

    func configureButton() {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        button.on(.touchUpInside) { [weak self] _ in
            self?.editCustomTimeRangeHandler?()
        }
        stackView.addArrangedSubview(button)
    }

    func configureSelectedDateLabel() {
        selectedDateLabel.font = Constants.labelFont
        selectedDateLabel.textColor = Constants.labelColor
        selectedDateLabel.textAlignment = Constants.labelTextAlignment
        selectedDateLabel.isHidden = true
        stackView.addArrangedSubview(selectedDateLabel)
    }
}

private extension StatsTimeRangeBarView {
    enum Constants {
        static let stackViewInset = UIEdgeInsets(top: 15, left: 16, bottom: 10, right: 16)
        static let labelFont: UIFont = .footnote
        static let labelColor: UIColor = .secondaryLabel
        static let labelTextAlignment: NSTextAlignment = .center
        static let imagePadding: CGFloat = 8
        static let stackViewSpacing: CGFloat = 0
    }
}
