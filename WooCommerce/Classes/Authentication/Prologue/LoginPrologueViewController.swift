import Foundation
import UIKit
import WordPressAuthenticator


/// Displays the WooCommerce Prologue UI.
///
class LoginPrologueViewController: UIViewController {

    /// Label to be displayed at the top of the Prologue.
    ///
    @IBOutlet var upperLabel: UILabel!

    /// Default Action Button.
    ///
    @IBOutlet var loginButton: UIButton!


    // MARK: - Overriden Properties

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }


    // MARK: - Overriden Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainView()
        setupUpperLabel()
        setupLoginButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}


// MARK: - Initialization Methods
//
private extension LoginPrologueViewController {

    func setupMainView() {
        view.backgroundColor = StyleManager.wooCommerceBrandColor
    }

    func setupUpperLabel() {
        upperLabel.text = NSLocalizedString("Check your WooCommerce store on\nthe go, fulfill your orders and get\nnotifications of new sales.", comment: "Login Prologue Legend")
        upperLabel.font = UIFont.font(forStyle: .subheadline, weight: .bold)
        upperLabel.textColor = .white
    }

    func setupLoginButton() {
        let title = NSLocalizedString("Log in with Jetpack", comment: "Authentication Login Button")
        loginButton.setTitle(title, for: .normal)
    }
}


// MARK: - Action Handlers
//
extension LoginPrologueViewController {

    @IBAction func loginWasPressed() {
        let loginViewController = WordPressAuthenticator.signinForWordPress()
        loginViewController.restrictToWPCom = true
        loginViewController.offerSignupOption = false
        navigationController?.pushViewController(loginViewController, animated: true)
    }
}
