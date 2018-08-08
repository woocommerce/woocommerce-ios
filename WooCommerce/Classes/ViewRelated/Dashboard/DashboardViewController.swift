import UIKit
import Gridicons


// MARK: - DashboardViewController
//
class DashboardViewController: UIViewController {

    // MARK: - View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tabBarItem.image = Gridicon.iconOfType(.statsAlt)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func setupNavigation() {
        title = NSLocalizedString("My Store", comment: "Dashboard navigation title")
        let rightBarButton = UIBarButtonItem(image: Gridicon.iconOfType(.cog),
                                             style: .plain,
                                             target: self,
                                             action: #selector(settingsTapped))
        rightBarButton.tintColor = .white
        navigationItem.setRightBarButton(rightBarButton, animated: false)

        // Don't show the Dashboard title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }

    // MARK: - Actions

    @objc func settingsTapped() {
        performSegue(withIdentifier: Constants.settingsSegue, sender: nil)
    }
}

// MARK: - Constants
//
private extension DashboardViewController {
    struct Constants {
        static let settingsSegue = "ShowSettingsViewController"
    }
}
