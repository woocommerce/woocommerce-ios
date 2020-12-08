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

    private let actionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    // StackView to hold the action buttons. Needed to change the axis on larger accessibility traits
    private let buttonsStackView = UIStackView()

    private let actionButtons: [UIButton]

    private let isActionEnabled: Bool

    private(set) var isExpanded: Bool

    private let onTopButtonTapped: (() -> Void)?

    init(viewModel: TopBannerViewModel) {
        isActionEnabled = viewModel.actionButtons.isNotEmpty
        isExpanded = viewModel.isExpanded
        onTopButtonTapped = viewModel.topButton.handler
        actionButtons = viewModel.actionButtons.map { _ in UIButton() }
        super.init(frame: .zero)
        configureSubviews(with: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TopBannerView {
    func configureSubviews(with viewModel: TopBannerViewModel) {
        let mainStackView = createMainStackView(with: viewModel)
        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView)

        titleLabel.applyHeadlineStyle()
        titleLabel.numberOfLines = 0

        infoLabel.applyBodyStyle()
        infoLabel.numberOfLines = 0

        renderContent(of: viewModel)
        configureBannerType(type: viewModel.type)
        updateStackViewsAxis()
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

        zip(viewModel.actionButtons, actionButtons).forEach { buttonInfo, button in
            button.setTitle(buttonInfo.title, for: .normal)
            button.on(.touchUpInside, call: { _ in buttonInfo.action() })
        }
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

        case .none:
            break
        }
    }

    func createMainStackView(with viewModel: TopBannerViewModel) -> UIStackView {
        let iconInformationStackView = createIconInformationStackView(with: viewModel)
        let mainStackView = UIStackView(arrangedSubviews: [iconInformationStackView, createBorderView()])
        if isActionEnabled {
            configureActionStackView(with: viewModel)
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
        let titleStackView = UIStackView(arrangedSubviews: [titleLabel, topActionButton].compactMap { $0 })
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

    func configureActionStackView(with viewModel: TopBannerViewModel) {
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.spacing = 0.5

        // Background to simulate a separator by giving the buttons some spacing
        let separatorBackground = createButtonsBackgroundView()
        buttonsStackView.addSubview(separatorBackground)
        buttonsStackView.pinSubviewToAllEdges(separatorBackground)

        // Style buttons
        actionButtons.forEach { button in
            button.applyLinkButtonStyle()
            button.backgroundColor = backgroundColor(for: viewModel.type)
            buttonsStackView.addArrangedSubview(button)
        }

        // Bundle everything with a vertical separator
        actionStackView.addArrangedSubviews([buttonsStackView, createBorderView()])
    }

    func createButtonsBackgroundView() -> UIView {
        let separatorBackground = UIView()
        separatorBackground.translatesAutoresizingMaskIntoConstraints = false
        separatorBackground.backgroundColor = .systemColor(.separator)
        return separatorBackground
    }

    func createBorderView() -> UIView {
        return UIView.createBorderView()
    }

    func topButton(for buttonType: TopBannerViewModel.TopButtonType) -> UIButton? {
        switch buttonType {
        case .chevron:
            return expandCollapseButton
        case .dismiss:
            return dismissButton
        case .none:
            return nil
        }
    }

    func configureBannerType(type: TopBannerViewModel.BannerType) {
        switch type {
        case .normal:
            iconImageView.tintColor = .textSubtle
        case .warning:
            iconImageView.tintColor = .warning
        }
        backgroundColor = backgroundColor(for: type)
    }

    func backgroundColor(for bannerType: TopBannerViewModel.BannerType) -> UIColor {
        switch bannerType {
        case .normal:
            return .systemColor(.secondarySystemGroupedBackground)
        case .warning:
            return .warningBackground
        }
    }

    /// Changes the axis of the stack views that need special treatment on larger size categories
    ///
    func updateStackViewsAxis() {
        buttonsStackView.axis = traitCollection.preferredContentSizeCategory > .extraExtraExtraLarge ? .vertical : .horizontal
    }
}

private extension TopBannerView {
    @objc func onDismissButtonTapped() {
        onTopButtonTapped?()
    }

    @objc func onExpandCollapseButtonTapped() {
        self.isExpanded = !isExpanded
        updateExpandCollapseState(isExpanded: isExpanded)
        onTopButtonTapped?()
    }
}

// MARK: Accessibility Handling
//
extension TopBannerView {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateStackViewsAxis()
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

        let accessibleView = isExpanded ? infoLabel : nil
        UIAccessibility.post(notification: .layoutChanged, argument: accessibleView)
    }
}
