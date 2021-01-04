import UIKit

/// A view that contains a primary-styled button. This is typically used as an action button and
/// set as the `UITableView.tableFooterView`.
///
final class ButtonTableFooterView: UIView {

    private let button = UIButton()

    private let onButtonPress: (() -> Void)?

    /// Initialize self.
    ///
    /// - Parameters:
    ///     - frame: The frame of self. You probably just want this to be `.zero` if since
    ///              `UITableView` would usually change this.
    ///     - title: The title of the button.
    ///     - onButtonPress: The callback to call if the button is pressed.
    ///
    init(frame: CGRect, title: String, onButtonPress: (() -> Void)?) {
        self.onButtonPress = onButtonPress
        super.init(frame: frame)
        configureButton(title: title)
    }

    override init(frame: CGRect) {
        self.onButtonPress = nil
        super.init(frame: frame)
        configureButton(title: "")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ButtonTableFooterView {

    func configureButton(title: String) {
        preservesSuperviewLayoutMargins = true

        button.applyPrimaryButtonStyle()
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(sendButtonPressedEvent), for: .touchUpInside)

        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)

        configureButtonConstraints()
    }

    private func configureButtonConstraints() {
        let trailingConstraint = layoutMarginsGuide.trailingAnchor.constraint(equalTo: button.trailingAnchor)
        trailingConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            layoutMarginsGuide.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            trailingConstraint,
            layoutMarginsGuide.topAnchor.constraint(equalTo: button.topAnchor, constant: -Dimensions.buttonTopInset),
            layoutMarginsGuide.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: Dimensions.buttonBottomInset),
        ])
    }

    @objc func sendButtonPressedEvent() {
        onButtonPress?()
    }

    enum Dimensions {
        static let buttonTopInset: CGFloat = 16
        static let buttonBottomInset: CGFloat = 64
    }
}
