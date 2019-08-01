import UIKit

protocol DashboardUI: UIViewController {
    var refreshControl: UIRefreshControl { get }
    func defaultAccountDidUpdate()
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
