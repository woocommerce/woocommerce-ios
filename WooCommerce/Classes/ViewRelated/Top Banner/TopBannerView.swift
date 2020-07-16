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

    private lazy var actionStackView = createActionStackView()

    private let isActionEnabled: Bool

    private(set) var isExpanded: Bool

    private let onTopButtonTapped: (() -> Void)?
    private let onAction: (() -> Void)?

    init(viewModel: TopBannerViewModel) {
        isActionEnabled = viewModel.actionHandler != nil
        isExpanded = viewModel.isExpanded
        onAction = viewModel.actionHandler
        onTopButtonTapped = viewModel.topButton.handler
        super.init(frame: .zero)
        configureSubviews(with: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TopBannerView {
    func configureSubviews(with viewModel: TopBannerViewModel) {
        configureBackground()

        let mainStackView = createMainStackView(with: viewModel)
        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView)

        iconImageView.tintColor = .textSubtle

        titleLabel.applyHeadlineStyle()
        titleLabel.numberOfLines = 0

        infoLabel.applyBodyStyle()
        infoLabel.numberOfLines = 0

        if isActionEnabled {
            actionButton.applyLinkButtonStyle()
            actionButton.addTarget(self, action: #selector(onActionButtonTapped), for: .touchUpInside)
        }

        renderContent(of: viewModel)
    }

    func renderContent(of viewModel: TopBannerViewModel) {
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

    func configureTopButton(viewModel: TopBannerViewModel, onContentView contentView: UIView) {
        switch viewModel.topButton {
        case .chevron:
            updateExpandCollapseState(isExpanded: isExpanded)
            expandCollapseButton.tintColor = .textSubtle

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onExpandCollapseButtonTapped))
            tapGesture.cancelsTouchesInView = false
            contentView.addGestureRecognizer(tapGesture)

        case .dismiss:
            dismissButton.setImage(UIImage.gridicon(.cross, size: CGSize(width: 24, height: 24)), for: .normal)
            dismissButton.tintColor = .textSubtle
            dismissButton.addTarget(self, action: #selector(onDismissButtonTapped), for: .touchUpInside)
        }
    }

    func configureBackground() {
        backgroundColor = .systemColor(.secondarySystemGroupedBackground)
    }

    func createMainStackView(with viewModel: TopBannerViewModel) -> UIStackView {
        let iconInformationStackView = createIconInformationStackView(with: viewModel)
        let mainStackView = UIStackView(arrangedSubviews: [iconInformationStackView, createBorderView()])
        if isActionEnabled {
            mainStackView.addArrangedSubview(actionStackView)
        }

        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .vertical
        return mainStackView
    }

    func createIconInformationStackView(with viewModel: TopBannerViewModel) -> UIStackView {
        let informationStackView = createInformationStackView(with: viewModel)
        let iconInformationStackView = UIStackView(arrangedSubviews: [iconImageView, informationStackView])

        iconInformationStackView.translatesAutoresizingMaskIntoConstraints = false
        iconInformationStackView.axis = .horizontal
        iconInformationStackView.spacing = 16
        iconInformationStackView.alignment = .leading
        iconInformationStackView.layoutMargins = .init(top: 16, left: 16, bottom: 16, right: 16)
        iconInformationStackView.isLayoutMarginsRelativeArrangement = true
        configureTopButton(viewModel: viewModel, onContentView: iconInformationStackView)

        return iconInformationStackView
    }

    func createInformationStackView(with viewModel: TopBannerViewModel) -> UIStackView {
        let topActionButton = topButton(for: viewModel.topButton)
        let titleStackView = UIStackView(arrangedSubviews: [titleLabel, topActionButton])
        titleStackView.axis = .horizontal
        titleStackView.spacing = 16

        let informationStackView = UIStackView(arrangedSubviews: [titleStackView, infoLabel])
        informationStackView.axis = .vertical
        informationStackView.spacing = 9

        iconImageView.setContentHuggingPriority(.required, for: .horizontal)
        iconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        dismissButton.setContentHuggingPriority(.required, for: .horizontal)
        dismissButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        expandCollapseButton.setContentHuggingPriority(.required, for: .horizontal)
        expandCollapseButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        return informationStackView
    }

    func createActionStackView() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [actionButton, createBorderView()])
        stackView.axis = .vertical
        return stackView
    }

    func createBorderView() -> UIView {
        return UIView.createBorderView()
    }

    func topButton(for buttonType: TopBannerViewModel.TopButtonType) -> UIButton {
        switch buttonType {
        case .chevron:
            return expandCollapseButton
        case .dismiss:
            return dismissButton
        }
    }
}

private extension TopBannerView {
    @objc func onDismissButtonTapped() {
        onTopButtonTapped?()
    }

    @objc func onActionButtonTapped() {
        onAction?()
    }

    @objc func onExpandCollapseButtonTapped() {
        self.isExpanded = !isExpanded
        updateExpandCollapseState(isExpanded: isExpanded)
        onTopButtonTapped?()
    }
}

// MARK: UI Updates
//
private extension TopBannerView {
    func updateExpandCollapseState(isExpanded: Bool) {
        let image = isExpanded ? UIImage.chevronUpImage: UIImage.chevronDownImage
        expandCollapseButton.setImage(image, for: .normal)
        infoLabel.isHidden = !isExpanded
        if isActionEnabled {
            actionStackView.isHidden = !isExpanded
        }
    }
}
