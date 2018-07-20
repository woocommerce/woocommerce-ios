import Foundation
import UIKit
import Yosemite


/// Renders the Order Fulfillment Interface
///
class FulfillViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet private var tableView: UITableView!

    /// The Order that's about to be fulfilled.
    ///
    let order: Order

    /// Designated Initializer
    ///
    init(order: Order) {
        self.order = order
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    /// NSCoder Conformance
    ///
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }


    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItem()
        setupMainView()
    }
}


// MARK: - Interface Initialization
//
private extension FulfillViewController {

    /// Setup: Navigation Item
    ///
    func setupNavigationItem() {
        title = NSLocalizedString("Fulfill Order #\(order.number)", comment: "Order Fulfillment Title")
    }

    /// Setup: Main View
    ///
    func setupMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension FulfillViewController: UITableViewDataSource {

}


// MARK: - UITableViewDelegate Conformance
//
extension FulfillViewController: UITableViewDelegate {

}
