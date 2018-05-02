import UIKit

class OrderDetailsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var viewModel: OrderDetailsViewModel!
    var orderNotes: [OrderNote]?

    static let sectionFooterHeight = CGFloat(30)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        title = viewModel.title
    }

    func configureTableView() {
        tableView.estimatedSectionHeaderHeight = 0
        configureNibs()
    }

    func configureNibs() {
        let summaryNib = UINib(nibName: OrderDetailsSummaryCell.reuseIdentifier, bundle: nil)
        tableView.register(summaryNib, forCellReuseIdentifier: OrderDetailsSummaryCell.reuseIdentifier)
        let noteNib = UINib(nibName: OrderDetailsCustomerNoteCell.reuseIdentifier, bundle: nil)
        tableView.register(noteNib, forCellReuseIdentifier: OrderDetailsCustomerNoteCell.reuseIdentifier)
        let infoNib = UINib(nibName: OrderDetailsCustomerInfoCell.reuseIdentifier, bundle: nil)
        tableView.register(infoNib, forCellReuseIdentifier: OrderDetailsCustomerInfoCell.reuseIdentifier)
        let footerNib = UINib(nibName: ShowHideFooterCell.reuseIdentifier, bundle: nil)
        tableView.register(footerNib, forHeaderFooterViewReuseIdentifier: ShowHideFooterCell.reuseIdentifier)
    }
}

extension OrderDetailsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.getSectionTitles().count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rowCount(for: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            case OrderDetailsViewModel.Section.summary.rawValue:
                return viewModel.cellForSummarySection(indexPath: indexPath, tableView: tableView)
            case OrderDetailsViewModel.Section.customerNote.rawValue:
                return viewModel.cellForCustomerNoteSection(indexPath: indexPath, tableView: tableView)
            case OrderDetailsViewModel.Section.info.rawValue:
                return viewModel.cellForCustomerInfoSection(indexPath: indexPath, tableView: tableView)
            default:
                fatalError()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let titles = viewModel.getSectionTitles()
        if titles[section].isEmpty {
            return 0
        }
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let titles = viewModel.getSectionTitles()
        if titles[section].isEmpty {
            return nil
        }
        return titles[section]
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == OrderDetailsViewModel.Section.info.rawValue {
            return OrderDetailsViewController.sectionFooterHeight
        }
        return 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == OrderDetailsViewModel.Section.info.rawValue {
            return viewModel.cellForShowHideFooter(tableView: tableView, section: section)
        }
        return nil
    }
}

extension OrderDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
