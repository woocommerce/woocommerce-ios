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

        title = viewModel.refundAmount

        configureTableView()
    }
}

// MARK: - Provisioning

private extension RefundConfirmationViewController {
    func configureTableView() {
        // Register cells
        [
            SettingTitleAndValueTableViewCell.self,
            TitleAndEditableValueTableViewCell.self,
            HeadlineLabelTableViewCell.self
        ].forEach(tableView.registerNib)

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
            cell.selectionStyle = .none
            return cell
        case let row as RefundConfirmationViewModel.TitleAndEditableValueRow:
            let cell = tableView.dequeueReusableCell(TitleAndEditableValueTableViewCell.self, for: indexPath)
            cell.update(title: row.title, placeholder: row.placeholder)
            return cell
        case let row as RefundConfirmationViewModel.TitleAndBodyRow:
            let cell = tableView.dequeueReusableCell(HeadlineLabelTableViewCell.self, for: indexPath)
            cell.update(style: .regular, headline: row.title, body: row.body)
            cell.selectionStyle = .none
            return cell
        default:
            assertionFailure("Unsupported row.")
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.sections[safe: section]?.title
    }
}
