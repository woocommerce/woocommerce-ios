import UIKit
import Yosemite


// MARK: - RefundedProductsViewController: Displays a list of all the refunded products.
//
final class RefundedProductsViewController: UIViewController {
    /// Main TableView.
    ///
    @IBOutlet private weak var tableView: UITableView!

    /// Order we're observing.
    ///
    private let order: Order

    /// Array of full refunds.
    ///
    private(set) var refunds: [Refund]

    /// Designated initalizer.
    ///
    init(order: Order, refunds: [Refund]) {
        self.order = order
        self.refunds = refunds
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    /// NSCoder conformance.
    ///
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}
