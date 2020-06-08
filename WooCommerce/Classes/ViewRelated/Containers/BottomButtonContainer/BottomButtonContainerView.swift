import UIKit

/// Contains a button with insets to be displayed at the bottom of a view.
///
final class BottomButtonContainerView: UIView {
    /// The style of the button.
    enum ButtonStyle {
        case primary
        case link
    }

    struct ViewModel {
        let style: ButtonStyle
        let title: String
        let image: UIImage?
        let onButtonTapped: (UIButton) -> Void

        init(style: ButtonStyle, title: String, onButtonTapped: @escaping (UIButton) -> Void) {
            self.init(style: style, title: title, image: nil, onButtonTapped: onButtonTapped)
        }

        init(style: ButtonStyle, title: String, image: UIImage?, onButtonTapped: @escaping (UIButton) -> Void) {
            self.style = style
            self.title = title
            self.image = image
            self.onButtonTapped = onButtonTapped
        }
    }

    private let button: UIButton = UIButton(type: .custom)

    private let viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        configureContainerView()
        configureButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension BottomButtonContainerView {
    func configureContainerView() {
        backgroundColor = .basicBackground

        let topBorderView = UIView.createBorderView()
        addSubview(topBorderView)
        NSLayoutConstraint.activate([
            topBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBorderView.topAnchor.constraint(equalTo: topAnchor)
        ])
    }

    func configureButton() {
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(button, insets: Constants.buttonMarginInsets)

        button.setTitle(viewModel.title, for: .normal)
        button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
        button.titleLabel?.lineBreakMode = .byTruncatingTail

        switch viewModel.style {
        case .primary:
            button.applyPrimaryButtonStyle()
        case .link:
            button.applyLinkButtonStyle()
            button.contentHorizontalAlignment = .leading
            button.contentEdgeInsets = .zero
        }

        if let image = viewModel.image {
            button.setImage(image, for: .normal)
            button.distributeTitleAndImage(spacing: Constants.buttonTitleAndImageSpacing)
        }
    }

    @objc func buttonTapped(sender: UIButton) {
        viewModel.onButtonTapped(sender)
    }
}

private extension BottomButtonContainerView {
    enum Constants {
        static let buttonMarginInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        static let buttonTitleAndImageSpacing: CGFloat = 16
    }
}
