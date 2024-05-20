import Foundation
import UIKit

final class TitleAndSubtitleAndValueCardTableViewCell: UITableViewCell {

    /// Title label
    ///
    private let titleLabel = UILabel()

    /// Subtitle label
    ///
    private let subtitleLabel = UILabel()

    /// Value label
    ///
    private let valueLabel = UILabel()

    /// Main view for the cell, to create a border
    ///
    private lazy var mainView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.borderWidth = Constants.borderWidth
        view.layer.borderColor = UIColor.border.cgColor
        return view
    }()

    /// Main stack view
    ///
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = Constants.spacingBetweenTitlesAndValue
        return stackView
    }()

    /// Stack view for title and subtitle
    ///
    private lazy var titleAndSubtitleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .leading
        return stackView
    }()

    /// Default top anchor constraint for content view
    ///
    private lazy var contentViewTopAnchorConstraint: NSLayoutConstraint = {
        contentView.topAnchor.constraint(equalTo: mainView.topAnchor, constant: -Constants.insets.top)
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureDefaultBackgroundConfiguration()
        enableMultipleLines()
        configureSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}

// MARK: UI Update
extension TitleAndSubtitleAndValueCardTableViewCell {
    func configure(row: Int, title: String, subtitle: String, value: String) {
        titleLabel.text = title
        titleLabel.applyBodyStyle()

        subtitleLabel.text = subtitle
        subtitleLabel.applyFootnoteStyle()

        valueLabel.text = value
        valueLabel.applyBodyStyle()

        hideSeparator()
        setInsets(for: row)
    }

    /// Removes the default top anchor inset when the cell isn't the first row in the section.
    ///
    func setInsets(for row: Int) {
        if row == 0 {
            contentViewTopAnchorConstraint.constant = -Constants.insets.top
        } else {
            contentViewTopAnchorConstraint.constant = 0
        }
    }
}

private extension TitleAndSubtitleAndValueCardTableViewCell {
    /// Needed specially when dealing with big accessibility traits
    ///
    func enableMultipleLines() {
        titleLabel.numberOfLines = 0
        subtitleLabel.numberOfLines = 0
        valueLabel.numberOfLines = 0
    }

    func configureSubviews() {
        contentView.addSubview(mainView)
        NSLayoutConstraint.activate([
            contentViewTopAnchorConstraint,
            contentView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: -Constants.insets.left),
            contentView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: Constants.insets.right),
            contentView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor, constant: Constants.insets.bottom),
        ])

        mainView.addSubview(stackView)
        mainView.pinSubviewToAllEdges(stackView, insets: Constants.insets)

        stackView.addArrangedSubviews([titleAndSubtitleStackView, valueLabel])
        titleAndSubtitleStackView.addArrangedSubviews([titleLabel, subtitleLabel])
    }

    enum Constants {
        static let spacingBetweenTitlesAndValue: CGFloat = 12
        static let cornerRadius: CGFloat = 5
        static let borderWidth: CGFloat = 1
        static let insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
}
