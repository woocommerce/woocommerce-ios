import MessageUI


/// Email picker presenter
class LinkMailPresenter {
    /// Presents the available mail clients in an action sheet. If none is available,
    /// Falls back to Apple Mail and opens it.
    /// If not even Apple Mail is available, presents an alert to check your email
    /// - Parameters:
    ///   - viewController: the UIViewController that will present the action sheet
    ///   - appSelector: the app picker that contains the available clients. Nil if no clients are available
    ///                  reads the supported email clients from EmailClients.plist
    func presentEmailClients(on viewController: UIViewController,
                             appSelector: AppSelector? = AppSelector()) {

        guard let picker = appSelector else {
            // fall back to Apple Mail if no other clients are installed
            if MFMailComposeViewController.canSendMail(), let url = URL(string: "message://") {
                UIApplication.shared.open(url)
            } else {
                showAlertToCheckEmail(on: viewController)
            }
            return
        }
        viewController.present(picker.alertController, animated: true)
    }

    private func showAlertToCheckEmail(on viewController: UIViewController) {
        let title = NSLocalizedString("Please check your email", comment: "Alert title for check your email during logIn/signUp.")
        let message = NSLocalizedString("Please open your email app and look for an email from WordPress.com.", comment: "Message to ask the user to check their email and look for a WordPress.com email.")

        let alertController =  UIAlertController(title: title,
                                                 message: message,
                                                 preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("OK",
                                                                   comment: "Button title. An acknowledgement of the message displayed in a prompt."))
        viewController.present(alertController, animated: true, completion: nil)
    }
}
