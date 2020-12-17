import UIKit
import Yosemite

/// Displays information about the refund with a CTA to request a refund.
final class RefundShippingLabelViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var refundButton: UIButton!

    private let shippingLabel: ShippingLabel
    private let viewModel: RefundShippingLabelViewModel
    private let rows: [Row]
    private let noticePresenter: NoticePresenter
    private let onComplete: () -> Void

    init(shippingLabel: ShippingLabel,
         currencyFormatter: CurrencyFormatter = .init(currencySettings: ServiceLocator.currencySettings),
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         onComplete: @escaping () -> Void) {
        self.shippingLabel = shippingLabel
        self.viewModel = RefundShippingLabelViewModel(shippingLabel: shippingLabel, currencyFormatter: currencyFormatter)
        self.rows = [.purchaseDate, .refundableAmount]
        self.noticePresenter = noticePresenter
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureTableView()
        configureRefundButton()
    }
}

// MARK: Action Handling
private extension RefundShippingLabelViewController {
    func refundShippingLabel() {
        viewModel.refundShippingLabel { result in
            self.showRefundResultNotice(result: result)
        }
        onComplete()
    }

    func showRefundResultNotice(result: Result<ShippingLabelRefund, Error>) {
        let notice: Notice
        switch result {
        case .success:
            let title = String.localizedStringWithFormat(Localization.refundSuccessNoticeFormat, shippingLabel.serviceName, viewModel.refundableAmount)
            notice = Notice(title: title, feedbackType: .success)
        case .failure(let error):
            DDLogError("⛔️ Failed to request a refund for shipping label \(shippingLabel.shippingLabelID): \(error)")
            notice = Notice(title: Localization.refundErrorNotice, feedbackType: .error)
        }
        noticePresenter.enqueue(notice: notice)
    }
}

// MARK: Configuration
private extension RefundShippingLabelViewController {
    func configureNavigationBar() {
        navigationItem.title = Localization.navigationBarTitle
    }

    func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        registerTableViewCellsAndHeader()

        tableView.applyFooterViewForHidingExtraRowPlaceholders()
        tableView.backgroundColor = .basicBackground
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.bounces = false
    }

    func registerTableViewCellsAndHeader() {
        // Rows.
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
        // Header.
        tableView.register(PlainTextSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: PlainTextSectionHeaderView.reuseIdentifier)
    }

    func configureRefundButton() {
        refundButton.applyPrimaryButtonStyle()
        refundButton.setTitle(viewModel.refundButtonTitle, for: .normal)
        refundButton.on(.touchUpInside) { [weak self] _ in
            self?.refundShippingLabel()
        }
    }

    func configureCellCommonProperties(_ cell: ValueOneTableViewCell) {
        cell.detailTextLabel?.textColor = Constants.cellValueTextColor
        cell.selectionStyle = .none
        cell.accessoryType = .none
    }
}

extension RefundShippingLabelViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row)
        return cell
    }
}

extension RefundShippingLabelViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerID = PlainTextSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? PlainTextSectionHeaderView else {
            fatalError()
        }
        headerView.label.applySubheadlineStyle()
        headerView.label.text = Localization.headerText
        headerView.label.textColor = Constants.cellValueTextColor
        return headerView
    }
}

private extension RefundShippingLabelViewController {
    func configure(_ cell: UITableViewCell, for row: Row) {
        switch cell {
        case let cell as ValueOneTableViewCell where row == .purchaseDate:
            configurePurchaseDate(cell: cell)
        case let cell as ValueOneTableViewCell where row == .refundableAmount:
            configureRefundableAmount(cell: cell)
        default:
            break
        }
    }

    func configurePurchaseDate(cell: ValueOneTableViewCell) {
        cell.textLabel?.text = Localization.purchaseDateTitle
        cell.detailTextLabel?.text = viewModel.purchaseDate
        configureCellCommonProperties(cell)
    }

    func configureRefundableAmount(cell: ValueOneTableViewCell) {
        cell.textLabel?.text = Localization.refundableAmountTitle
        cell.detailTextLabel?.text = viewModel.refundableAmount
        configureCellCommonProperties(cell)
    }
}

private extension RefundShippingLabelViewController {
    enum Constants {
        static let cellValueTextColor = UIColor.systemColor(.secondaryLabel)
        static let sectionHeight = CGFloat(44)
    }

    enum Localization {
        static let navigationBarTitle = NSLocalizedString("Request a Refund",
                                                          comment: "Navigation bar title to request a refund for a shipping label")
        static let headerText = NSLocalizedString(
            "You can request a refund for a shipping label that has not been used to ship a package.\nIt will take a least 14 days to process.",
            comment: "Header text in Refund Shipping Label screen")
        static let purchaseDateTitle = NSLocalizedString("Purchase Date",
                                                         comment: "Title of shipping label purchase date in Refund Shipping Label screen")
        static let refundableAmountTitle = NSLocalizedString("Amount Eligible For Refund",
                                                             comment: "Title of shipping label eligible refund amount in Refund Shipping Label screen")
        static let refundSuccessNoticeFormat =
            NSLocalizedString("%1$@ refund requested (%2$@)",
                              comment: "Notice format when a shipping label refund request is successful. " +
                                "The first variable shows the shipping label service name (e.g. USPS Priority Mail). " +
                                "The second variable shows the formatted amount that is eligible for refund  (e.g. $7.50).")
        static let refundErrorNotice = NSLocalizedString("Something went wrong with the refund. Please try again.",
                                                         comment: "Notice format when a shipping label refund request fails.")
    }
}

private extension RefundShippingLabelViewController {
    enum Row: CaseIterable {
        case purchaseDate
        case refundableAmount

        var type: UITableViewCell.Type {
            ValueOneTableViewCell.self
        }

        var reuseIdentifier: String {
            type.reuseIdentifier
        }
    }
}
