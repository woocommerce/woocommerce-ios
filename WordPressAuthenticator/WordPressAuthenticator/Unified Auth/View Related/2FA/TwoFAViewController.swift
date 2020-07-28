import UIKit

final class TwoFAViewController: LoginViewController {

    // MARK: - Properties
    @IBOutlet private weak var tableView: UITableView!

    // TODO: add support tag

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.logInTitle
        styleNavigationBar(forUnified: true)

        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)
        
        localizePrimaryButton()
    }
    
    // MARK: - Overrides

    override func styleBackground() {
        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            super.styleBackground()
            return
        }

        view.backgroundColor = unifiedBackgroundColor
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return WordPressAuthenticator.shared.unifiedStyle?.statusBarStyle ??
               WordPressAuthenticator.shared.style.statusBarStyle
    }

}

// MARK: - UITableViewDataSource

extension TwoFAViewController: UITableViewDataSource {

    /// Returns the number of rows in a section.
    ///
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // TODO: update when real cells are added.
        return 1
    }

    /// Configure cells delegate method.
    ///
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: update when real cells are added.
        return UITableViewCell()
    }

}
