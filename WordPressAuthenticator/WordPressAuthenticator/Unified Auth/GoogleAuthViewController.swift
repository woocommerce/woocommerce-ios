
/// View controller that handles the google authentication flow
///
class GoogleAuthViewController: LoginViewController {

    // MARK: - Properties

    private var hasShownGoogle = false
    @IBOutlet var titleLabel: UILabel?

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .wpComAuthWaitingForGoogle
        }
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel?.text = LocalizedText.waitingForGoogle
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showGoogleScreenIfNeeded()
    }

}

// MARK: - Private Methods

private extension GoogleAuthViewController {

    func showGoogleScreenIfNeeded() {
        guard !hasShownGoogle else {
            return
        }

        // Flag this as a social sign in.
        loginFields.meta.socialService = .google

        // TODO: kick off GoogleAuthenticator here
        // GoogleAuthenticator.sharedInstance.signupDelegate = self
        // GoogleAuthenticator.sharedInstance.showFrom(viewController: self, loginFields: loginFields, for: .signup)
        // hasShownGoogle = true
    }

    enum LocalizedText {
        // TODO: use real message
        static let waitingForGoogle = NSLocalizedString("I AM LEGEND!!!", comment: "Message shown on screen while waiting for Google to finish its process.")
    }

}
