import UIKit

/// Contains a button with insets to be displayed at the bottom of a view.
///
final class BottomButtonContainerView: UIView {
    struct ViewModel {
        /// Allows the view model to configure and style the button.
        let configureButton: (UIButton) -> Void

        /// Called when the button is tapped.
        let onButtonTapped: (UIButton) -> Void
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

        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

        viewModel.configureButton(button)
    }

    @objc func buttonTapped(_ sender: UIButton) {
        viewModel.onButtonTapped(sender)
    }
}

private extension BottomButtonContainerView {
    enum Constants {
        static let buttonMarginInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
}
