import UIKit
import Yosemite

/// The list-facing contract used by `OrdersRootViewController`.
///
/// Keeping UIKit ownership behind this protocol lets the root controller switch between the legacy
/// table view and the Store Design System SwiftUI implementation without duplicating navigation.
@MainActor
protocol OrderListPresenting: AnyObject {
    var delegate: OrderListViewControllerDelegate? { get set }
    var viewController: UIViewController { get }
    var contentScrollView: UIScrollView? { get }
    var onFilterTapped: (() -> Void)? { get set }

    func observeContentScrollView(_ observer: @escaping (UIScrollView) -> Void)
    func updateFilters(count: Int, readableDescription: String?)
    func updateLastSyncTime(_ time: String)

    func selectOrderFromListIfPossible(for orderID: Int64,
                                       isTriggeredByUserAction: Bool,
                                       shouldScrollIfNeeded: Bool) -> Bool
    func onOrderSelected(id orderID: Int64, shouldScrollIfNeeded: Bool)
    func selectShownOrderIfListed(id orderID: Int64)
    func restoreSelectedOrderDetails()
    func showOrderDetails(_ order: Order, shouldScrollIfNeeded: Bool, onCompletion: ((Bool) -> Void)?)
    func showErrorNotice(_ notice: Notice, in viewController: UIViewController)
}

extension OrderListViewController: OrderListPresenting {
    var viewController: UIViewController { self }
    var contentScrollView: UIScrollView? { tableView }
    var onFilterTapped: (() -> Void)? {
        get { nil }
        set { }
    }

    func observeContentScrollView(_ observer: @escaping (UIScrollView) -> Void) {
        loadViewIfNeeded()
        observer(tableView)
    }

    func updateFilters(count: Int, readableDescription: String?) { }
    func updateLastSyncTime(_ time: String) { }
}
