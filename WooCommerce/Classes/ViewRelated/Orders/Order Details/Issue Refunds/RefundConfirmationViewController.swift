import Foundation
import UIKit

/// Presents a screen to confirm the refund with the user.
///
/// Shows the total amount to be refunded and allows the user to enter the reason for the refund.
///
final class RefundConfirmationViewController: UIViewController {

    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "$amount_to_refund"

        configureTableView()
    }
}

// MARK: - Provisioning

private extension RefundConfirmationViewController {
    func configureTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(tableView)
    }
}
