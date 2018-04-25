import UIKit

class SingleOrderViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var viewModel: SingleOrderViewModel!
    var orderNotes: [OrderNote]?

    static let sectionFooterHeight = CGFloat(30)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        title = viewModel.title
    }

    func configureTableView() {
        configureNibs()
    }

    func configureNibs() {
        let summaryNib = UINib(nibName: SingleOrderSummaryCell.reuseIdentifier, bundle: nil)
        tableView.register(summaryNib, forCellReuseIdentifier: SingleOrderSummaryCell.reuseIdentifier)
        let noteNib = UINib(nibName: SingleOrderCustomerNoteCell.reuseIdentifier, bundle: nil)
        tableView.register(noteNib, forCellReuseIdentifier: SingleOrderCustomerNoteCell.reuseIdentifier)
        let infoNib = UINib(nibName: SingleOrderCustomerInfoCell.reuseIdentifier, bundle: nil)
        tableView.register(infoNib, forCellReuseIdentifier: SingleOrderCustomerInfoCell.reuseIdentifier)
        let footerNib = UINib(nibName: ShowHideFooterCell.reuseIdentifier, bundle: nil)
        tableView.register(footerNib, forHeaderFooterViewReuseIdentifier: ShowHideFooterCell.reuseIdentifier)
    }
}

extension SingleOrderViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.getSectionTitles().count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rowCount(for: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == viewModel.summarySection {
            return viewModel.cellForSummarySection(indexPath: indexPath, tableView: tableView)
        }

        if indexPath.section == viewModel.customerNoteSection {
            return viewModel.cellForCustomerNoteSection(indexPath: indexPath, tableView: tableView)
        }

        if indexPath.section == viewModel.customerInfoSection {
            return viewModel.cellForCustomerInfoSection(indexPath: indexPath, tableView: tableView)
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let titles = viewModel.getSectionTitles()
        return titles[section]
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == viewModel.customerInfoSection {
            return SingleOrderViewController.sectionFooterHeight
        }
        return 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == viewModel.customerInfoSection {
            return viewModel.cellForShowHideFooter(tableView: tableView, section: section)
        }
        return nil
    }
}

extension SingleOrderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
