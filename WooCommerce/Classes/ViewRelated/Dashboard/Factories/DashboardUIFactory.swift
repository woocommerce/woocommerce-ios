import UIKit

protocol DashboardUI: UIViewController {
    /// For the user to refresh the Dashboard
    var refreshControl: UIRefreshControl { get }

    /// Called when the user pulls to refresh
    var onPullToRefresh: () -> Void { get set }

    /// Called when the default account was updated
    func defaultAccountDidUpdate()

    /// Reloads data in Dashboard
    ///
    /// - Parameter completion: called when Dashboard data reload finishes
    func reloadData(completion: @escaping () -> Void)
}

extension DashboardUI {
    func displaySyncingErrorNotice() {
        let title = NSLocalizedString("My store", comment: "My Store Notice Title for loading error")
        let message = NSLocalizedString("Unable to load content", comment: "Load Action Failed")
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: title, message: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.refreshControl.beginRefreshing()
            self?.reloadData {}
        }

        AppDelegate.shared.noticePresenter.enqueue(notice: notice)
    }
}

final class DashboardUIFactory {
    static func dashboardUI() -> DashboardUI {
        return DashboardStatsV3ViewController(nibName: nil, bundle: nil)
    }
}
