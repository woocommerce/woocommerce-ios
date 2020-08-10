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
    
    // MARK: - Button Handling

    @IBAction func handleSubmit() {
        tracker.track(click: .submit)
        
        configureSubmitButton(animating: true)
        GoogleAuthenticator.sharedInstance.delegate = self
        GoogleAuthenticator.sharedInstance.createGoogleAccount(loginFields: loginFields)
    }

}

// MARK: - GoogleAuthenticatorDelegate

extension GoogleSignupConfirmationViewController: GoogleAuthenticatorDelegate {
    
    // MARK: - Signup
    
    func googleFinishedSignup(credentials: AuthenticatorCredentials, loginFields: LoginFields) {
        self.loginFields = loginFields
        showSignupEpilogue(for: credentials)
    }

    func googleLoggedInInstead(credentials: AuthenticatorCredentials, loginFields: LoginFields) {
        self.loginFields = loginFields
        showLoginEpilogue(for: credentials)
    }
    
    func googleSignupFailed(error: Error, loginFields: LoginFields) {
        configureSubmitButton(animating: false)
        self.loginFields = loginFields

        // Display generic inline error.
        displayError(message: NSLocalizedString("Google sign up failed.", comment: "Message shown on screen after the Google sign up process failed."))
        // Display the API error in a Fancy Alert.
        displayError(error as NSError, sourceTag: .wpComSignup)
    }
    
    // MARK: - Login

    func googleFinishedLogin(credentials: AuthenticatorCredentials, loginFields: LoginFields) {
        // Here for protocol compliance.
    }
    
    func googleNeedsMultifactorCode(loginFields: LoginFields) {
        // Here for protocol compliance.
    }
    
    func googleExistingUserNeedsConnection(loginFields: LoginFields) {
        // Here for protocol compliance.
    }
    
    func googleLoginFailed(errorTitle: String, errorDescription: String, loginFields: LoginFields, unknownUser: Bool) {
        // Here for protocol compliance.
    }

    func googleAuthCancelled() {
        // Here for protocol compliance.
    }

}
