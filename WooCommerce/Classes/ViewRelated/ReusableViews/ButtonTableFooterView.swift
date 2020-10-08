import UIKit

/// A view that contains a primary-styled button. This is typically used as an action button and
/// set as the `UITableView.tableFooterView`.
///
final class ButtonTableFooterView: UIView {

    private let button = UIButton()

    private let onButtonPress: (() -> Void)?

    init(frame: CGRect, title: String, onButtonPress: (() -> Void)?) {
        self.onButtonPress = onButtonPress
        super.init(frame: frame)
        setupButton(title: title)
    }

    override init(frame: CGRect) {
        self.onButtonPress = nil
        super.init(frame: frame)
        setupButton(title: "")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ButtonTableFooterView {
    func setupButton(title: String) {
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
