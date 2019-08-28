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
        return label
    }()

    private lazy var dismissButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let onDismiss: () -> Void
    private let onAction: () -> Void

    init(viewModel: TopBannerViewModel) {
        onDismiss = viewModel.dismissHandler
        onAction = viewModel.actionHandler
        super.init(frame: .zero)
        configureSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TopBannerView {
    func configureSubviews() {
        let textStackView = UIStackView(arrangedSubviews: [titleLabel, infoLabel])
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        textStackView.axis = .vertical
        textStackView.spacing = 3

        let contentStackView = UIStackView(arrangedSubviews: [iconImageView, textStackView, dismissButton])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .horizontal
        contentStackView.spacing = 0

        let borderView = createBorderView()

        let stackView = UIStackView(arrangedSubviews: [contentStackView, borderView, actionButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(stackView)
    }

    func configureSubviews(viewModel: TopBannerViewModel) {
        titleLabel.text = viewModel.title
        titleLabel.isHidden = viewModel.title?.isEmpty == true
        infoLabel.text = viewModel.infoText
        infoLabel.isHidden = viewModel.title?.isEmpty == true

        iconImageView.image = viewModel.icon

        dismissButton.setImage(Gridicon.iconOfType(.cross, withSize: CGSize(width: 24, height: 24)), for: .normal)
        dismissButton.addTarget(self, action: #selector(onDismissButtonTapped), for: .touchUpInside)

        actionButton.setTitle(viewModel.actionButtonTitle, for: .normal)
        actionButton.addTarget(self, action: #selector(onActionButtonTapped), for: .touchUpInside)
//        actionButton.titleLabel?.font = StyleManager.fon
    }

    func createBorderView() -> UIView {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = StyleManager.wooGreyBorder
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 1)
            ])
        return view
    }
}

private extension TopBannerView {
    @objc private func onDismissButtonTapped() {
        onDismiss()
    }

    @objc private func onActionButtonTapped() {
        onAction()
    }
}
