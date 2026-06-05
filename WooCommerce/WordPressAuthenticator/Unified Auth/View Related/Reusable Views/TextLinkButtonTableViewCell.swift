import UIKit

/// TextLinkButtonTableViewCell: a plain button made to look like a text link.
///
class TextLinkButtonTableViewCell: UITableViewCell {

    /// Private properties
    ///
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var borderView: UIView!
    @IBOutlet private weak var borderWidth: NSLayoutConstraint!
    @IBOutlet private weak var iconViewWidth: NSLayoutConstraint!
    @IBOutlet private weak var iconTrailingPadding: NSLayoutConstraint!

    @IBAction private func textLinkButtonTapped(_ sender: UIButton) {
        actionHandler?()
    }

    /// Public properties
    ///
    public static let reuseIdentifier = "TextLinkButtonTableViewCell"

    public var actionHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        button.titleLabel?.adjustsFontForContentSizeCategory = true
        styleBorder()
    }

    public func configureButton(text: String?,
                                icon: UIImage? = nil,
                                accessibilityTrait: UIAccessibilityTraits = .button,
                                showBorder: Bool = false,
                                accessibilityIdentifier: String? = nil) {
        button.setTitle(text, for: .normal)

        let buttonTitleColor = WordPressAuthenticator.shared.unifiedStyle?.textButtonColor ?? WordPressAuthenticator.shared.style.textButtonColor
        let buttonHighlightColor = WordPressAuthenticator.shared.unifiedStyle?.textButtonHighlightColor ?? WordPressAuthenticator.shared.style.textButtonHighlightColor
        button.setTitleColor(buttonTitleColor, for: .normal)
        button.setTitleColor(buttonHighlightColor, for: .highlighted)
        button.accessibilityTraits = accessibilityTrait
        button.accessibilityIdentifier = accessibilityIdentifier

        borderView.isHidden = !showBorder

        iconView.image = icon
        iconView.tintColor = buttonTitleColor

        let noIcon = icon == nil
        iconView.isHidden = noIcon
        iconViewWidth.constant = noIcon ? 0 : Constants.iconWidth
        iconTrailingPadding.constant = noIcon ? 0 : Constants.iconTrailingPadding
    }

    /// Toggle button enabled / disabled
    ///
    public func enableButton(_ isEnabled: Bool) {
        button.isEnabled = isEnabled
    }
}

// MARK: - Private methods
private extension TextLinkButtonTableViewCell {

    /// Style the bottom cell border, called borderView.
    ///
    func styleBorder() {
        let borderColor = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        borderView.backgroundColor = borderColor
        borderWidth.constant = WPStyleGuide.hairlineBorderWidth
    }
}

// MARK: - Constants
extension TextLinkButtonTableViewCell {
    struct Constants {
        static let passkeysID = "Passkeys"
        static let iconWidth: CGFloat = 20
        static let iconTrailingPadding: CGFloat = 16
    }
}
