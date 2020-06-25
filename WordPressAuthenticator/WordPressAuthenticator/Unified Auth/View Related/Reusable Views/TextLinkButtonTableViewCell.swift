import UIKit


/// TextLinkButtonTableViewCell: a plain button made to look like a text link.
///
class TextLinkButtonTableViewCell: UITableViewCell {

    /// Private properties
    ///
    @IBOutlet private weak var button: UIButton!
    @IBAction private func textLinkButtonTapped(_ sender: UIButton) {
        actionHandler?()
    }

    /// Public properties
    ///
    public static let reuseIdentifier = "TextLinkButtonTableViewCell"

    public var actionHandler: (() -> Void)?

	override func awakeFromNib() {
		super.awakeFromNib()

		button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
		button.titleLabel?.adjustsFontForContentSizeCategory = true
		button.titleLabel?.lineBreakMode = .byWordWrapping
	}

    public func configureButton(text: String?) {
        button.setTitle(text, for: .normal)

        let buttonTitleColor = WordPressAuthenticator.shared.unifiedStyle?.textButtonColor ?? WordPressAuthenticator.shared.style.textButtonColor
        let buttonHighlightColor = WordPressAuthenticator.shared.unifiedStyle?.textButtonHighlightColor ?? WordPressAuthenticator.shared.style.textButtonHighlightColor
        button.setTitleColor(buttonTitleColor, for: .normal)
        button.setTitleColor(buttonHighlightColor, for: .highlighted)
    }
}
