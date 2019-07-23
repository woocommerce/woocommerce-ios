import UIKit

class TrackingNumberImageDetectionResultTableViewCell: UITableViewCell {
    private lazy var titleLabel: UILabel = {
        return UILabel()
    }()

    private lazy var detailLabel: UILabel = {
        return UILabel()
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        configureSubviews()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TrackingNumberImageDetectionResultTableViewCell {
    func update(title: String? = nil, detail: String? = nil) {
        titleLabel.text = title
        detailLabel.text = detail
    }
}

private extension TrackingNumberImageDetectionResultTableViewCell {
    func configureSubviews() {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        configureStackView(stackView: stackView)
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdgeMargins(stackView)

        detailLabel.setContentHuggingPriority(.required, for: .horizontal)

        configureTitleLabel()
        configureDetailLabel()
    }

    func configureStackView(stackView: UIStackView) {
        stackView.axis = .horizontal
        stackView.spacing = 7
    }

    func configureTitleLabel() {
        titleLabel.applyBodyStyle()
        titleLabel.numberOfLines = 0
    }

    func configureDetailLabel() {
        detailLabel.applyFootnoteStyle()
    }
}
