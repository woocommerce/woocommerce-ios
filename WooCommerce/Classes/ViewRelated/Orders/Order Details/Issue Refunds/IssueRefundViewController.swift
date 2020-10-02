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
        configureTableView()
    }
}

// MARK: View Configuration
private extension IssueRefundViewController {
    func configureTableView() {
        registerCells()
        tableView.delegate = self
        tableView.dataSource = self
    }

    func registerCells() {
        tableView.registerNib(for: RefundItemTableViewCell.self)
        tableView.registerNib(for: RefundProductsTotalTableViewCell.self)
        tableView.registerNib(for: RefundShippingDetailsTableViewCell.self)
        tableView.registerNib(for: SwitchTableViewCell.self)
    }
}

// MARK: TableView Delegate & DataSource
extension IssueRefundViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell?
        switch indexPath.row {
        case 0...2:
            let  itemCell = tableView.dequeueReusableCell(RefundItemTableViewCell.self, for: indexPath)
            let viewModel = RefundItemViewModel(productImage: nil,
                                                productTitle: "Sample Product",
                                                productQuantityAndPrice: "2 x $10.00 each",
                                                quantityToRefund: "1")
            itemCell.configure(with: viewModel)
            cell = itemCell
        case 3:
            let totalCell = tableView.dequeueReusableCell(RefundProductsTotalTableViewCell.self, for: indexPath)
            let viewModel = RefundProductsTotalViewModel(productsTax: "$3.40", productsSubtotal: "$10.00", productsTotal: "$13.40")
            totalCell.configure(with: viewModel)
            cell = totalCell
        case 4:
            let switchCell = tableView.dequeueReusableCell(SwitchTableViewCell.self, for: indexPath)
            switchCell.title = "Refund Shipping"
            cell = switchCell
        case 5:
            let shippingCell = tableView.dequeueReusableCell(RefundShippingDetailsTableViewCell.self, for: indexPath)
            let viewModel = RefundShippingDetailsViewModel(carrierRate: "USPS Flat Rate",
                                                           carrierCost: "$7.40",
                                                           shippingTax: "$2.0",
                                                           shippingSubtotal: "$7.40",
                                                           shippingTotal: "$9.40")
            shippingCell.configure(with: viewModel)
            cell = shippingCell
        default:
            fatalError("Cell creation error")
        }
        return cell!
    }
}
