import Foundation
import UIKit

/// Presents a screen to confirm the refund with the user.
///
/// Shows the total amount to be refunded and allows the user to enter the reason for the refund.
///
final class RefundConfirmationViewController: UIViewController {

    private lazy var tableView = UITableView(frame: .zero, style: .grouped)
    private let viewModel = RefundConfirmationViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "$amount_to_refund"

        configureTableView()
    }
}

// MARK: - Provisioning

private extension RefundConfirmationViewController {
    func configureTableView() {
        // Register cells
        tableView.register(SettingTitleAndValueTableViewCell.loadNib(),
                           forCellReuseIdentifier: SettingTitleAndValueTableViewCell.reuseIdentifier)

        // Delegation
        tableView.dataSource = self

        // Style
        tableView.backgroundColor = .listBackground

        // Add to view
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(tableView)
    }
}

// MARK: - UITableView Boom

extension RefundConfirmationViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[safe: section]?.rows.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = viewModel.sections[safe: indexPath.section]?.rows[safe: indexPath.row] else {
            return UITableViewCell()
        }

        switch row {
        case let row as RefundConfirmationViewModel.TwoColumnRow:
            let cell = tableView.dequeueReusableCell(SettingTitleAndValueTableViewCell.self, for: indexPath)
            cell.updateUI(title: row.title, value: row.value)
            if row.isHeadline {
                cell.applyHeadlineLabelsStyle()
            } else {
                cell.applyDefaultLabelsStyle()
            }
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.sections[safe: section]?.title
    }
}
