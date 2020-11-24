import UIKit
import Yosemite

/// Screen that allows the user to refund items (products and shipping) of an order
///
final class IssueRefundViewController: UIViewController {

    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var tableFooterView: UIView!
    @IBOutlet private var tableHeaderView: UIView!

    @IBOutlet private var itemsSelectedLabel: UILabel!
    @IBOutlet private var nextButton: UIButton!
    @IBOutlet private var selectAllButton: UIButton!

    private let imageService: ImageService

    private let viewModel: IssueRefundViewModel

    init(order: Order,
         refunds: [Refund],
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         imageService: ImageService = ServiceLocator.imageService) {
        self.imageService = imageService
        self.viewModel = IssueRefundViewModel(order: order, refunds: refunds, currencySettings: currencySettings)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureTableView()
        observeViewModel()
        updateWithViewModelContent()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.updateHeaderHeight()
        tableView.updateFooterHeight()
    }
}

// MARK: ViewModel observation
private extension IssueRefundViewController {
    func observeViewModel() {
        viewModel.onChange = { [weak self] in
            self?.updateWithViewModelContent()
        }
    }

    func updateWithViewModelContent() {
        title = viewModel.title
        itemsSelectedLabel.text = viewModel.selectedItemsTitle
        nextButton.isEnabled = viewModel.isNextButtonEnabled
        tableView.reloadData()
    }
}

// MARK: Actions
private extension IssueRefundViewController {
    @IBAction func nextButtonWasPressed(_ sender: Any) {
        let confirmationViewModel = viewModel.createRefundConfirmationViewModel()
        show(RefundConfirmationViewController(viewModel: confirmationViewModel), sender: self)

        viewModel.trackNextButtonTapped()
    }

    @IBAction func selectAllButtonWasPressed(_ sender: Any) {
        viewModel.selectAllOrderItems()
    }

    func shippingSwitchChanged() {
        viewModel.toggleRefundShipping()
    }

    func quantityButtonPressed(sender: UITableViewCell) {
        guard let indexPath = tableView.indexPath(for: sender),
            let refundQuantity = viewModel.quantityAvailableForRefundForItemAtIndex(indexPath.row),
            let currentQuantity = viewModel.currentQuantityForItemAtIndex(indexPath.row) else {
                return
        }

        let command = RefundItemQuantityListSelectorCommand(maxRefundQuantity: refundQuantity, currentQuantity: currentQuantity)
        let selectorViewController = ListSelectorViewController(command: command, tableViewStyle: .plain) { [weak self] selectedQuantity in
            guard let selectedQuantity = selectedQuantity else {
                return
            }
            self?.viewModel.updateRefundQuantity(quantity: selectedQuantity, forItemAtIndex: indexPath.row)
        }
        show(selectorViewController, sender: nil)
        viewModel.trackQuantityButtonTapped()
    }
}

// MARK: View Configuration
private extension IssueRefundViewController {

    func configureNavigationBar() {
        addCloseNavigationBarButton(title: Localization.cancelTitle)
    }

    func configureTableView() {
        registerCells()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .listBackground
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = tableFooterView
        configureFooterView()
        configureHeaderView()
    }

    func registerCells() {
        tableView.registerNib(for: RefundItemTableViewCell.self)
        tableView.registerNib(for: RefundProductsTotalTableViewCell.self)
        tableView.registerNib(for: RefundShippingDetailsTableViewCell.self)
        tableView.registerNib(for: SwitchTableViewCell.self)
    }

    func configureHeaderView() {
        selectAllButton.applyLinkButtonStyle()
        selectAllButton.contentEdgeInsets = .zero
        selectAllButton.setTitle(Localization.selectAllTitle, for: .normal)

        itemsSelectedLabel.applySecondaryBodyStyle()
    }

    func configureFooterView() {
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
            cell.configure(with: viewModel, imageService: imageService)
            cell.onQuantityTapped = { [weak self] in
                self?.quantityButtonPressed(sender: cell)
            }
            return cell
        case let viewModel as RefundProductsTotalViewModel:
            let cell = tableView.dequeueReusableCell(RefundProductsTotalTableViewCell.self, for: indexPath)
            cell.configure(with: viewModel)
            return cell
        case let viewModel as IssueRefundViewModel.ShippingSwitchViewModel:
            let cell = tableView.dequeueReusableCell(SwitchTableViewCell.self, for: indexPath)
            cell.title = viewModel.title
            cell.isOn = viewModel.isOn
            cell.onChange = { [weak self] _ in
                self?.shippingSwitchChanged()
            }
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
        static let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel button title in the issue refund screen")
        static let selectAllTitle = NSLocalizedString("Select All", comment: "Select all button title in the issue refund screen")
    }
}
