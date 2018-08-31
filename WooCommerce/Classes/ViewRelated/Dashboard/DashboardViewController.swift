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
        newOrdersContainerView.isHidden = true // Hide the new orders vc by default
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
        applyHideAnimation(for: newOrdersContainerView)
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

    func applyUnhideAnimation(for view: UIView) {
        UIView.animate(withDuration: Constants.showAnimationDuration,
                       delay: 0,
                       usingSpringWithDamping: Constants.showSpringDamping,
                       initialSpringVelocity: Constants.showSpringVelocity,
                       options: .curveEaseOut,
                       animations: {
                        view.isHidden = false
                        view.alpha = 1.0
        }) { _ in
            view.isHidden = false
            view.alpha = 1.0
        }
    }

    func applyHideAnimation(for view: UIView) {
        UIView.animate(withDuration: Constants.hideAnimationDuration, animations: {
            view.isHidden = true
            view.alpha = 0.0
        }, completion: { _ in
            view.isHidden = true
            view.alpha = 0.0
        })
    }
}


// MARK: - Constants
//
private extension DashboardViewController {
    struct Constants {
        static let settingsSegue    = "ShowSettingsViewController"
        static let storeStatsSegue  = "StoreStatsEmbedSegue"
        static let newOrdersSegue   = "NewOrdersEmbedSegue"

        static let hideAnimationDuration: TimeInterval = 0.25
        static let showAnimationDuration: TimeInterval = 0.50
        static let showSpringDamping: CGFloat = 0.7
        static let showSpringVelocity: CGFloat = 0.0
    }
}
