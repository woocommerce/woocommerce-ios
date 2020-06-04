import UIKit

class GoogleSignupConfirmationViewController: LoginViewController {

    // MARK: - Properties
    
    @IBOutlet weak var emailField: LoginTextField!

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .wpComAuthGoogleSignupConfirmation
        }
    }
    
    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        localizeControls()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        emailField.text = loginFields.emailAddress
        emailField.isEnabled = false
        emailField.backgroundColor = WordPressAuthenticator.shared.style.viewControllerBackgroundColor
        
        configureSubmitButton(animating: false)
    }
    
}

// MARK: - Private Extension

private extension GoogleSignupConfirmationViewController {
    
    func localizeControls() {
        instructionLabel?.text = NSLocalizedString("We'll use this email address to create your new WordPress.com account.", comment: "Text confirming email address to be used for new account.")
        emailField.accessibilityIdentifier = "Google Signup Email Address"
        emailField.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton?.setTitle(submitButtonTitle, for: .normal)
        submitButton?.setTitle(submitButtonTitle, for: .highlighted)
        submitButton?.accessibilityIdentifier = "Google Signup Email Next Button"
    }
    
    // MARK: - Button Action Handling

    @IBAction func handleSubmit() {
        displayError(message: "Cheers!")
        // TODO: create account.
        // TODO: re-enable this when handling added.
        // configureSubmitButton(animating: true)
    }

}
