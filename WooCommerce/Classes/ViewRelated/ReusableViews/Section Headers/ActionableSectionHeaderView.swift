import UIKit

final class ActionableSectionHeaderView: UITableViewHeaderFooterView {
    /// Custom configurations for the CTA.
    struct ActionConfiguration {
        let image: UIImage
        let actionHandler: (_ sourceView: UIView) -> Void
    }

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = ""
        titleLabel.applySubheadlineStyle()
        return titleLabel
    }()

    private lazy var actionButton: UIButton = {
        let actionButton = UIButton()
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.isHidden = true
        actionButton.setTitle(nil, for: .normal)
        actionButton.setContentHuggingPriority(.required, for: .horizontal)
        return actionButton
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private var actionHandler: ((_ sourceView: UIView) -> Void)?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(actionButton)

        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdges(stackView, insets: Constants.contentViewMargin)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String?, action: ActionConfiguration? = nil) {
        titleLabel.text = title
        actionButton.isHidden = action == nil

        if let action = action {
            actionButton.applyIconButtonStyle(icon: action.image)
            actionHandler = action.actionHandler
            actionButton.addTarget(self, action: #selector(onAction(_:)), for: .touchUpInside)
        }
    }
}

private extension ActionableSectionHeaderView {
    @objc func onAction(_ sourceView: UIView) {
        actionHandler?(sourceView)
    }
}

private extension ActionableSectionHeaderView {
    enum Constants {
        static let contentViewMargin = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
}
