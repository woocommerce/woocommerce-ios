import UIKit

/// Screen that allows the user to refund items (products and shipping) of an order
///
final class IssueRefundViewController: UIViewController {

    @IBOutlet private var tableView: UITableView!

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: View Configuration
private extension IssueRefundViewController {
    func registerCells() {
        tableView.register(RefundItemTableViewCell.loadNib(), forCellReuseIdentifier: RefundItemTableViewCell.reuseIdentifier)
        tableView.register(RefundProductsTotalTableViewCell.loadNib(), forCellReuseIdentifier: RefundProductsTotalTableViewCell.reuseIdentifier)
        tableView.register(RefundShippingDetailsTableViewCell.loadNib(), forCellReuseIdentifier: RefundShippingDetailsTableViewCell.reuseIdentifier)
        tableView.register(SwitchTableViewCell.loadNib(), forCellReuseIdentifier: SwitchTableViewCell.reuseIdentifier)
    }
}
