import UIKit
import Gridicons
import CocoaLumberjack


// MARK: - DashboardViewController
//
class DashboardViewController: UIViewController {

    // MARK: Properties

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var newOrdersContainerView: UIView!

    private var storeStatsViewController: StoreStatsViewController!
    private var newOrdersViewController: NewOrdersViewController!

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
            storeStatsViewController = vc
        }
        if let vc = segue.destination as? NewOrdersViewController, segue.identifier == Constants.newOrdersSegue {
            newOrdersViewController = vc
            newOrdersViewController.delegate = self
        }
    }
}


// MARK: - Configuration
//
private extension DashboardViewController {

    func configureView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        scrollView.refreshControl = refreshControl
        hideNewOrders()
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
private extension DashboardViewController {

    @objc func settingsTapped() {
        performSegue(withIdentifier: Constants.settingsSegue, sender: nil)
    }

    @objc func pullToRefresh() {
        hideNewOrders()
        reloadData()
    }
}


// MARK: - NewOrdersDelegate Conformance
//
extension DashboardViewController: NewOrdersDelegate {
    func didUpdateNewOrdersData(hasNewOrders: Bool) {
        if hasNewOrders {
            applyUnhideAnimation(for: newOrdersContainerView)
        } else {
            applyHideAnimation(for: newOrdersContainerView)
        }
    }
}


// MARK: - Private Helpers
//
private extension DashboardViewController {
    func reloadData() {
        DDLogInfo("♻️ Requesting dashboard data be reloaded...")
        storeStatsViewController.syncAllStats()
        newOrdersViewController.syncNewOrders()
        refreshControl.endRefreshing()
    }

    func hideNewOrders() {
        newOrdersContainerView.isHidden = true
    }

    func applyUnhideAnimation(for view: UIView) {
        UIView.animate(withDuration: Constants.animationDuration) {
            view.isHidden = false
        }
    }

    func applyHideAnimation(for view: UIView) {
        UIView.animate(withDuration: Constants.animationDuration) {
            view.isHidden = true
        }
    }
}


// MARK: - Constants
//
private extension DashboardViewController {
    struct Constants {
        static let settingsSegue    = "ShowSettingsViewController"
        static let storeStatsSegue  = "StoreStatsEmbedSegue"
        static let newOrdersSegue   = "NewOrdersEmbedSegue"

        static let animationDuration: TimeInterval = 0.50
    }
}
