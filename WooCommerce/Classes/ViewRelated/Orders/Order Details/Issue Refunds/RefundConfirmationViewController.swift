import Foundation
import UIKit

/// Presents a screen to confirm the refund with the user.
///
/// Shows the total amount to be refunded and allows the user to enter the reason for the refund.
///
final class RefundConfirmationViewController: UIViewController {

    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    private let viewModel: RefundConfirmationViewModel

    init(viewModel: RefundConfirmationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.refundAmount

        configureMainView()
        configureTableView()
        configureButtonTableFooterView()
    }
}

// MARK: - Provisioning

private extension RefundConfirmationViewController {

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        // Register cells
        [
            SettingTitleAndValueTableViewCell.self,
            TitleAndEditableValueTableViewCell.self,
            HeadlineLabelTableViewCell.self,
            WooBasicTableViewCell.self
        ].forEach(tableView.registerNib)

        // Delegation
        tableView.dataSource = self

        // Style
        tableView.backgroundColor = .listBackground

        // Dimensions
        tableView.sectionFooterHeight = .leastNonzeroMagnitude

        // Add to view
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(tableView)
    }

    func configureButtonTableFooterView() {
        tableView.tableFooterView = ButtonTableFooterView(frame: .zero, title: Localization.refund) { [weak self] in
            guard let self = self else { return }
            self.displayConfirmationAlert { didConfirm in
                if didConfirm {
                    self.submitRefund()
                }
            }
        }
        tableView.updateFooterHeight()
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
                cell.apply(style: .headline)
            } else {
                cell.apply(style: .bodyConsistent)
            }
            cell.selectionStyle = .none
            return cell
        case let row as RefundConfirmationViewModel.TitleAndEditableValueRow:
            let cell = tableView.dequeueReusableCell(TitleAndEditableValueTableViewCell.self, for: indexPath)
            cell.update(style: .relaxed, viewModel: row.cellViewModel)
            return cell
        case let row as RefundConfirmationViewModel.TitleAndBodyRow:
            let cell = tableView.dequeueReusableCell(HeadlineLabelTableViewCell.self, for: indexPath)
            cell.update(style: .regular, headline: row.title, body: row.body)
            cell.selectionStyle = .none
            return cell
        case let row as RefundConfirmationViewModel.SimpleTextRow:
            let cell = tableView.dequeueReusableCell(WooBasicTableViewCell.self, for: indexPath)
            cell.applyPlainTextStyle()
            cell.bodyLabel.text = row.text
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

// MARK: - Confirmation And Submission
private extension RefundConfirmationViewController {

    /// Displays a confirmation alert before issuing a refund.
    /// - Parameter onCompletion: Closure to be invoked with the user selection. `True` continue with the refund. `False` cancel the refund.
    func displayConfirmationAlert(onCompletion: @escaping (Bool) -> Void) {

        let actionSheet = UIAlertController(title: Localization.confirmationTitle(amount: viewModel.refundAmount),
                                            message: Localization.confirmationBody,
                                            preferredStyle: .alert)
        actionSheet.addCancelActionWithTitle(Localization.cancel) { _ in
            onCompletion(false)
        }

        actionSheet.addActionWithTitle(Localization.refund, style: .default) { _ in
            onCompletion(true)
        }

        present(actionSheet, animated: true)
    }

    /// Submits the refund and dismisses the flow upon successful completion.
    ///
    func submitRefund() {
        self.viewModel.submit { [weak self] result in
            switch result {
            case .success:
                self?.dismiss(animated: true, completion: nil)
            case .failure(let error):
                DDLogError("Error issuing refund: \(error)")
            }
        }
    }
}

// MARK: - Localization

private extension RefundConfirmationViewController {
    enum Localization {
        static let refund = NSLocalizedString("Refund", comment: "The title of the button to confirm the refund.")
        static let cancel = NSLocalizedString("Cancel", comment: "The title of the button to cancel issuing a refund.")
        static let confirmationBody = NSLocalizedString("Are you sure you want to issue a refund? This can't be undone.",
                                                        comment: "The text on the confirmation alert before issuing a refund.")
        static func confirmationTitle(amount: String) -> String {
            "\(refund) \(amount)"
        }
    }
}
