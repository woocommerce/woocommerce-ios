import Gridicons
import UIKit

/// A full-width banner view to be shown at the top of a tab below the navigation bar.
/// Consists of an icon, text label, action button and dismiss button.
///
final class TopBannerView: UIView {
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: nil)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var infoLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "top-banner-view-info-label"
        return label
    }()

    private lazy var dismissButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "top-banner-view-dismiss-button"
        return button
    }()

    private lazy var expandCollapseButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "top-banner-view-expand-collapse-button"
        return button
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let isActionEnabled: Bool

    private(set) var isExpanded: Bool

    private let onDismiss: (() -> Void)?
    private let onAction: (() -> Void)?
    private let onExpandedStateChange: (() -> Void)?

    init(viewModel: TopBannerViewModel) {
        isActionEnabled = viewModel.actionHandler != nil
        isExpanded = viewModel.isExpanded
        onDismiss = viewModel.dismissHandler
        onAction = viewModel.actionHandler
        onExpandedStateChange = viewModel.expandedStateChangeHandler
        super.init(frame: .zero)
        configureSubviews()
        configureSubviews(viewModel: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TopBannerView {
    func configureSubviews() {
        configureBackground()

        let contentView = createContentView()
        let contentContainerView = createContentContainerView(contentView: contentView)
        let topLevelView = createTopLevelView(contentContainerView: contentContainerView)
        addSubview(topLevelView)
        pinSubviewToAllEdges(topLevelView)

        iconImageView.tintColor = .textSubtle

        titleLabel.applyHeadlineStyle()
        titleLabel.numberOfLines = 0

        infoLabel.applyBodyStyle()
        infoLabel.numberOfLines = 0

        if isActionEnabled {
            dismissButton.setImage(UIImage.gridicon(.cross, size: CGSize(width: 24, height: 24)), for: .normal)
            dismissButton.tintColor = .textSubtle
            dismissButton.addTarget(self, action: #selector(onDismissButtonTapped), for: .touchUpInside)

            actionButton.applyLinkButtonStyle()
            actionButton.addTarget(self, action: #selector(onActionButtonTapped), for: .touchUpInside)
        } else {
            updateExpandCollapseState(isExpanded: isExpanded)
            expandCollapseButton.tintColor = .textSubtle
            expandCollapseButton.addTarget(self, action: #selector(onExpandCollapseButtonTapped), for: .touchUpInside)
        }
    }

    func configureSubviews(viewModel: TopBannerViewModel) {
        if let title = viewModel.title, !title.isEmpty {
            titleLabel.text = title
        } else {
            // It is necessary to remove the subview when no text, otherwise the stack view spacing stays.
            titleLabel.removeFromSuperview()
        }

        if let infoText = viewModel.infoText, !infoText.isEmpty {
            infoLabel.text = infoText
        } else {
            // It is necessary to remove the subview when no text, otherwise the stack view spacing stays.
            infoLabel.removeFromSuperview()
        }

        iconImageView.image = viewModel.icon

        actionButton.setTitle(viewModel.actionButtonTitle, for: .normal)
    }

    func configureBackground() {
        backgroundColor = .systemColor(.secondarySystemGroupedBackground)
    }

    func createContentView() -> UIView {
        let textStackView = UIStackView(arrangedSubviews: [titleLabel, infoLabel])
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        textStackView.axis = .vertical
        textStackView.spacing = 3

        iconImageView.setContentHuggingPriority(.required, for: .horizontal)
        iconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        dismissButton.setContentHuggingPriority(.required, for: .horizontal)
        dismissButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        expandCollapseButton.setContentHuggingPriority(.required, for: .horizontal)
        expandCollapseButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let subviews: [UIView]
        if isActionEnabled {
            subviews = [iconImageView, textStackView, dismissButton]
        } else {
            subviews = [iconImageView, textStackView, expandCollapseButton]
        }
        let contentStackView = UIStackView(arrangedSubviews: subviews)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .horizontal
        contentStackView.spacing = 10
        contentStackView.alignment = .leading
        return contentStackView
    }

    func createContentContainerView(contentView: UIView) -> UIView {
        let contentContainerView = UIView(frame: .zero)
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(contentView)
        contentContainerView.pinSubviewToAllEdges(contentView, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 10))
        return contentContainerView
    }

    func createTopLevelView(contentContainerView: UIView) -> UIView {
        let subviews: [UIView]
        if isActionEnabled {
            subviews = [contentContainerView, createBorderView(), actionButton, createBorderView()]
        } else {
            subviews = [contentContainerView, createBorderView()]
        }
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }

    func createBorderView() -> UIView {
        return UIView.createBorderView()
    }
}

private extension TopBannerView {
    @objc func onDismissButtonTapped() {
        onDismiss?()
    }

    @objc func onActionButtonTapped() {
        onAction?()
    }

    @objc func onExpandCollapseButtonTapped() {
        self.isExpanded = !isExpanded
        updateExpandCollapseState(isExpanded: isExpanded)
        onExpandedStateChange?()
    }
}

// MARK: UI Updates
//
private extension TopBannerView {
    func updateExpandCollapseState(isExpanded: Bool) {
        let image = isExpanded ? UIImage.chevronUpImage: UIImage.chevronDownImage
        expandCollapseButton.setImage(image, for: .normal)
        infoLabel.isHidden = !isExpanded
    }
}
