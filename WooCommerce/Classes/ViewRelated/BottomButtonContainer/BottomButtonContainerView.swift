import UIKit

/// Contains a primary button with insets to be displayed at the bottom of a view.
///
final class BottomButtonContainerView: UIView {
    struct ViewModel {
        let buttonTitle: String
        let onButtonTapped: () -> Void
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
        pinSubviewToAllEdges(button, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))

        button.setTitle(viewModel.buttonTitle, for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.applyPrimaryButtonStyle()
    }

    @objc func buttonTapped() {
        viewModel.onButtonTapped()
    }
}
