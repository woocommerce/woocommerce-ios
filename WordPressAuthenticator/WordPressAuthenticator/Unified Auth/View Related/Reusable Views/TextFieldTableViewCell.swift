import UIKit


/// TextFieldTableViewCell: a textfield with a custom border line in a UITableViewCell.
///
final class TextFieldTableViewCell: UITableViewCell {

    /// Private properties.
    ///
    @IBOutlet private weak var borderView: UIView!
    @IBOutlet private weak var borderWidth: NSLayoutConstraint!
	private var secureTextEntryToggle: UIButton?
	private var secureTextEntryImageVisible: UIImage?
	private var secureTextEntryImageHidden: UIImage?

    private var hairlineBorderWidth: CGFloat {
        return 1.0 / UIScreen.main.scale
    }

    /// Public properties.
    ///
    @IBOutlet public weak var textField: UITextField! // public so it can be the first responder
	@IBInspectable public var showSecureTextEntryToggle: Bool = false {
		didSet {
			configureSecureTextEntryToggle()
		}
	}

    public static let reuseIdentifier = "TextFieldTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        styleBorder()
        setCommonTextFieldStyles()
    }

	/// Configures the textfield for URL, username, or entering a password.
	/// - Parameter style: changes the textfield behavior and appearance.
	/// - Parameter placeholder: the placeholder text, if any
	///
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

    /// Apply common keyboard traits and font styles.
    ///
    func setCommonTextFieldStyles() {
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.autocorrectionType = .no
    }

    /// Sets the textfield keyboard type and applies common traits.
    /// - note: Don't assign first responder here. It's too early in the view lifecycle.
    ///
    func applyTextFieldStyle(_ style: TextFieldStyle) {
		switch style {
        case .url:
            textField.keyboardType = .URL
			textField.returnKeyType = .continue
		case .username:
			textField.keyboardType = .default
			textField.returnKeyType = .next
		case .password:
			textField.keyboardType = .default
			textField.returnKeyType = .continue
			setSecureTextEntry(true)
			showSecureTextEntryToggle = true
			configureSecureTextEntryToggle()
        }
    }
}


// MARK: - Secure Text Entry
/// Methods ported from WPWalkthroughTextField.h/.m
///
private extension TextFieldTableViewCell {

	/// Build the show / hide icon in the textfield.
	///
	func configureSecureTextEntryToggle() {
		if showSecureTextEntryToggle == false {
			return
		}

		secureTextEntryImageVisible = UIImage.gridicon(.visible)
		secureTextEntryImageHidden = UIImage.gridicon(.notVisible)

		secureTextEntryToggle = UIButton(type: .custom)
		secureTextEntryToggle?.clipsToBounds = true

		secureTextEntryToggle?.addTarget(self,
										 action: #selector(secureTextEntryToggleAction),
										 for: .touchUpInside)

		updateSecureTextEntryToggleImage()
		updateSecureTextEntryForAccessibility()
		textField.rightView = secureTextEntryToggle
		textField.rightViewMode = .always
	}

	func setSecureTextEntry(_ secureTextEntry: Bool) {
		// This is a fix for a bug where the text field reverts to a system
		// serif font if you disable secure text entry while it contains text.
		textField.font = nil
		textField.font = UIFont.preferredFont(forTextStyle: .body)

		textField.isSecureTextEntry = secureTextEntry
		updateSecureTextEntryToggleImage()
		updateSecureTextEntryForAccessibility()
	}

	@objc func secureTextEntryToggleAction(_ sender: Any) {
		textField.isSecureTextEntry = !textField.isSecureTextEntry

		// Save and re-apply the current selection range to save the cursor position
		let currentTextRange = textField.selectedTextRange
		textField.becomeFirstResponder()
		textField.selectedTextRange = currentTextRange
		updateSecureTextEntryToggleImage()
		updateSecureTextEntryForAccessibility()
	}

	func updateSecureTextEntryToggleImage() {
		let image = textField.isSecureTextEntry ? secureTextEntryImageHidden : secureTextEntryImageVisible
		secureTextEntryToggle?.setImage(image, for: .normal)
		secureTextEntryToggle?.sizeToFit()
	}

	func updateSecureTextEntryForAccessibility() {
		secureTextEntryToggle?.accessibilityLabel = Constants.showPassword
		secureTextEntryToggle?.accessibilityValue = textField.isSecureTextEntry ? Constants.passwordHidden : Constants.passwordShown
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

	struct Constants {
		/// Accessibility Hints
		///
		static let passwordHidden = NSLocalizedString("Hidden",
													  comment: "Accessibility value if login page's password field is hiding the password (i.e. with asterisks).")
		static let passwordShown = NSLocalizedString("Shown",
													 comment: "Accessibility value if login page's password field is displaying the password.")
		static let showPassword = NSLocalizedString("Show password",
													comment:"Accessibility label for the 'Show password' button in the login page's password field.")

	}
}
