import UIKit

/// Displays a button inside a `UITableViewCell`.
///
final class ButtonTableViewCell: UITableViewCell {
    @IBOutlet private var button: ButtonActivityIndicator!
    @IBOutlet private weak var topConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!

    /// The style of this view, particularly the button.
    enum Style {
        /// Uses the primary button style. This is the default.
        case primary
        /// Uses the secondary button style.
        case secondary

        fileprivate static let `default` = Self.primary
    }

    private var onButtonTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        apply(style: .default)
    }

    /// Define this cell's UI attributes.
    ///
    /// - Parameters:
    ///   - style: The style of the cell.
    ///   - title: Button title.
    ///   - bottomSpacing: If non-nil, the value is set to the spacing between the button bottom edge and cell bottom edge.
    ///   - onButtonTouchUp: Called when the button is tapped.
    func configure(style: Style = .default,
                   title: String?,
                   topSpacing: CGFloat = Constants.defaultSpacing,
                   bottomSpacing: CGFloat = Constants.defaultSpacing,
                   onButtonTouchUp: (() -> Void)? = nil) {
        apply(style: style)
        button.setTitle(title, for: .normal)
        self.onButtonTouchUp = onButtonTouchUp

        topConstraint.constant = topSpacing
        bottomConstraint.constant = bottomSpacing
    }

    func enableButton(_ enabled: Bool) {
        button.isEnabled = enabled
    }

    func showActivityIndicator(_ show: Bool) {
        guard show else {
            button.hideActivityIndicator()
            return
        }
        button.showActivityIndicator()
    }
}

private extension ButtonTableViewCell {
    @IBAction func sendButtonTouchUpEvent() {
        onButtonTouchUp?()
    }
}

private extension ButtonTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func apply(style: Style) {
        switch style {
        case .primary:
            button.applyPrimaryButtonStyle()
        case .secondary:
            button.applySecondaryButtonStyle()
        }
    }
}

extension ButtonTableViewCell {
    enum Constants {
        static let defaultSpacing = CGFloat(20)
    }
}
