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
        button.applyPrimaryButtonStyle()
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(sendButtonPressedEvent), for: .touchUpInside)

        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        pinSubviewToSafeArea(button, insets: .init(top: Dimensions.buttonDefaultInset,
                                                   left: Dimensions.buttonDefaultInset,
                                                   bottom: Dimensions.buttonBottomInset,
                                                   right: Dimensions.buttonDefaultInset))
    }

    @objc func sendButtonPressedEvent() {
        onButtonPress?()
    }

    enum Dimensions {
        static let buttonDefaultInset: CGFloat = 16
        static let buttonBottomInset: CGFloat = 64
    }
}
