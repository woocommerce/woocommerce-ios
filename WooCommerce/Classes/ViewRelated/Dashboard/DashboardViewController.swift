import UIKit
import Gridicons
import CocoaLumberjack


// MARK: - DashboardViewController
//
class DashboardViewController: UIViewController {

    // MARK: Properties

    @IBOutlet private weak var scrollView: UIScrollView!
    private var storeStatsViewController: StoreStatsViewController!

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()

    // MARK: View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tabBarItem.image = Gridicon.iconOfType(.statsAlt)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureView()
        reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? StoreStatsViewController, segue.identifier == Constants.storeStatsSegue {
            self.storeStatsViewController = vc
        }
    }

}


// MARK: - Configuration
//
private extension DashboardViewController {

    func configureView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        scrollView.refreshControl = refreshControl
    }

    func configureNavigation() {
        title = NSLocalizedString("My Store", comment: "Dashboard navigation title")
        let rightBarButton = UIBarButtonItem(image: Gridicon.iconOfType(.cog),
                                             style: .plain,
                                             target: self,
                                             action: #selector(settingsTapped))
        rightBarButton.tintColor = .white
        rightBarButton.accessibilityLabel = NSLocalizedString("Settings", comment: "Accessibility label for the Settings button.")
        rightBarButton.accessibilityTraits = UIAccessibilityTraitButton
        rightBarButton.accessibilityHint = NSLocalizedString("Navigates to Settings.", comment: "VoiceOver accessibility hint, informing the user the button can be used to navigate to the Settings screen.")
        navigationItem.setRightBarButton(rightBarButton, animated: false)

        // Don't show the Dashboard title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }
}


// MARK: - Action Handlers
//
private extension DashboardViewController {

    @objc func settingsTapped() {
        performSegue(withIdentifier: Constants.settingsSegue, sender: nil)
    }

    @objc func pullToRefresh() {
        // FIXME: This code is just a WIP
        reloadData()
        refreshControl.endRefreshing()
        DDLogInfo("Reloading dashboard data.")
    }
}


// MARK: - Private Helpers
//
private extension DashboardViewController {
    func reloadData() {
        // FIXME: This code is just a WIP
        storeStatsViewController.syncAllStats()
    }
}


// MARK: - Constants
//
private extension DashboardViewController {
    struct Constants {
        static let settingsSegue    = "ShowSettingsViewController"
        static let storeStatsSegue  = "StoreStatsEmbedSeque"
    }
}
