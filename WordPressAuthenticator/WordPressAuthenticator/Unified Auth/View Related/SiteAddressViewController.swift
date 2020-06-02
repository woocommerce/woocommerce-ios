import UIKit


/// SiteAddressViewController: log in by Site Address.
///
final class SiteAddressViewController: LoginViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?

    var displayStrings: WordPressAuthenticatorDisplayStrings {
        return WordPressAuthenticator.shared.displayStrings
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        localizePrimaryButton()
    }

    func localizePrimaryButton() {
        let primaryTitle = displayStrings.continueButtonTitle
        submitButton?.setTitle(primaryTitle, for: .normal)
        submitButton?.setTitle(primaryTitle, for: .highlighted)
    }
}


// MARK: - UITableViewDataSource
extension SiteAddressViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "largetitlecell") ?? UITableViewCell()
        }

        if indexPath.row == 1 {
            return tableView.dequeueReusableCell(withIdentifier: "emailcell")  ?? UITableViewCell()
        }

        if indexPath.row == 2 {
            return tableView.dequeueReusableCell(withIdentifier: "instructionscell") ?? UITableViewCell()
        }

        if indexPath.row == 3 {
            return tableView.dequeueReusableCell(withIdentifier: "textfieldcell") ?? UITableViewCell()
        }

        if indexPath.row == 4 {
            return tableView.dequeueReusableCell(withIdentifier: "errorcell") ?? UITableViewCell()
        }

        if indexPath.row == 5 {
            return tableView.dequeueReusableCell(withIdentifier: "secondaryhelperbuttoncell") ?? UITableViewCell()
        }

        return UITableViewCell()
    }
}


// MARK: - UITableViewDelegate conformance
extension SiteAddressViewController: UITableViewDelegate {

}

// MARK: - Keyboard Notifications
extension SiteAddressViewController: NUXKeyboardResponder {
    var verticalCenterConstraint: NSLayoutConstraint? {
        // no-op
        return nil
    }

    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }


    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}
