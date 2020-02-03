
import UIKit

/// The main Orders view controller that is shown when the Orders tab is accessed.
///
/// TODO This should contain the tabs "Processing" and "All Orders".
///
final class OrdersMasterViewController: UIViewController {

    init() {
        super.init(nibName: Self.nibName, bundle: nil)

        tabBarItem.title = NSLocalizedString("Orders", comment: "Title of the Orders tab — plural form of Order")
        tabBarItem.image = .pagesImage
        tabBarItem.accessibilityIdentifier = "tab-bar-orders-item"
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let ordersViewController = OrdersViewController.instantiatedViewControllerFromStoryboard(),
            let ordersView = ordersViewController.view else {
            return
        }

        ordersView.translatesAutoresizingMaskIntoConstraints = false

        add(ordersViewController)
        view.addSubview(ordersView)
        ordersView.pinSubviewToAllEdges(view)
        ordersViewController.didMove(toParent: self)
    }
}
