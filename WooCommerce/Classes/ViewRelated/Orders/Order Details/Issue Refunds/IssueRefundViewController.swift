import UIKit

/// Screen that allows the user to refund items (products and shipping) of an order
///
final class IssueRefundViewController: UIViewController {

    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var tableFooterView: UIView!
    @IBOutlet private var nextButton: UIButton!

    private let viewModel = IssueRefundViewModel()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTitle()
        configureNextButton()
        configureTableView()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.updateFooterHeight()
    }
}

// MARK: Actions
private extension IssueRefundViewController {
    @IBAction func nextButtonWasPressed(_ sender: Any) {
        print("Next button pressed")
    }
}

// MARK: View Configuration
private extension IssueRefundViewController {

    func configureTitle() {
        title = viewModel.title
    }

    func configureTableView() {
        registerCells()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .listBackground
        tableView.tableFooterView = tableFooterView
    }

    func registerCells() {
        tableView.registerNib(for: RefundItemTableViewCell.self)
        tableView.registerNib(for: RefundProductsTotalTableViewCell.self)
        tableView.registerNib(for: RefundShippingDetailsTableViewCell.self)
        tableView.registerNib(for: SwitchTableViewCell.self)
    }

    func configureNextButton() {
        nextButton.applyPrimaryButtonStyle()
        nextButton.setTitle(Localization.nextTitle, for: .normal)
    }
}

// MARK: TableView Delegate & DataSource
extension IssueRefundViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[safe: section]?.rows.count ?? 0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let rowViewModel = viewModel.sections[safe: indexPath.section]?.rows[safe: indexPath.row] else {
            return UITableViewCell()
        }

        switch rowViewModel {
        case let viewModel as RefundItemViewModel:
            let cell = tableView.dequeueReusableCell(RefundItemTableViewCell.self, for: indexPath)
            cell.configure(with: viewModel)
            return cell
        case let viewModel as RefundProductsTotalViewModel:
            let cell = tableView.dequeueReusableCell(RefundProductsTotalTableViewCell.self, for: indexPath)
            cell.configure(with: viewModel)
            return cell
        case let viewModel as IssueRefundViewModel.ShippingSwitchViewModel:
            let cell = tableView.dequeueReusableCell(SwitchTableViewCell.self, for: indexPath)
            cell.title = viewModel.title
            cell.isOn = viewModel.isOn
            return cell
        case let viewModel as RefundShippingDetailsViewModel:
            let cell = tableView.dequeueReusableCell(RefundShippingDetailsTableViewCell.self, for: indexPath)
            cell.configure(with: viewModel)
            return cell
        default:
            return UITableViewCell()
        }
    }
}

// MARK: Constants
private extension IssueRefundViewController {
    enum Localization {
        static let nextTitle = NSLocalizedString("Next", comment: "Title of the next button in the issue refund screen")
    }
}
