import UIKit


/// TextFieldTableViewCell: a textfield with a custom border line in a UITableViewCell.
///
final class TextFieldTableViewCell: UITableViewCell {

    /// Private properties
    ///
    @IBOutlet private weak var borderView: UIView!
    @IBOutlet private weak var borderWidth: NSLayoutConstraint!

    private var hairlineBorderWidth: CGFloat {
        return 1.0 / UIScreen.main.scale
    }

    /// Public properties
    ///
    @IBOutlet public weak var textField: UITextField! // public so it can be the first responder

    public static let reuseIdentifier = "TextFieldTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        styleBorder()
        setCommonTextFieldStyles()
    }

    public func configureTextFieldStyle(with style: TextFieldStyle = .url, and placeholder: String?) {
        applyTextFieldStyle(style)
        textField.placeholder = placeholder
    }
}


// MARK: - Private methods
private extension TextFieldTableViewCell {

    /// Style the bottom cell border, called borderView.
    ///
    func styleBorder() {
        let borderColor = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        borderView.backgroundColor = borderColor
        borderWidth.constant = hairlineBorderWidth
    }

    /// Style the font inside the textField.
    ///
    func setCommonTextFieldStyles() {
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
    }

    /// Style the textField.
    /// - note: Don't assign first responder here. It's too early in the view lifecycle.
    ///
    func applyTextFieldStyle(_ style: TextFieldStyle) {
        switch style {
        case .url:
            textField.keyboardType = .URL
        default:
            setCommonTextFieldStyles()
        }
    }
}


// MARK: - Constants
extension TextFieldTableViewCell {

    /// TextField configuration options.
    ///
    enum TextFieldStyle {
        case url
        case username
        case password
    }
}
