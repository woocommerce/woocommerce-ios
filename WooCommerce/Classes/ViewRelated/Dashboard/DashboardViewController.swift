import UIKit
import Gridicons
import CocoaLumberjack


// MARK: - DashboardViewController
//
class DashboardViewController: UIViewController {

    // MARK: Properties

    @IBOutlet private weak var scrollView: UIScrollView!
    
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
    }
}


// MARK: - Configuration
//
extension DashboardViewController {

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
extension DashboardViewController {

    @objc func settingsTapped() {
        performSegue(withIdentifier: Constants.settingsSegue, sender: nil)
    }

    @objc func pullToRefresh() {
        // TODO: Implement pull-to-refresh
        self.refreshControl.endRefreshing()
        DDLogDebug("Pulling to refresh!")
    }
}


// MARK: - Constants
//
private extension DashboardViewController {
    struct Constants {
        static let settingsSegue = "ShowSettingsViewController"
    }
}
