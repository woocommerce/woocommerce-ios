import UIKit
import Yosemite

final class InPersonPaymentsTesterViewController: UITableViewController {
    init() {
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    struct Row {
        let label: String
        let targetState: CardPresentPaymentOnboardingState
    }

    private let model: [Row] = [
        Row(label: "Loading", targetState: .loading),
        Row(label: "Country not supported", targetState: .countryNotSupported(countryCode: "ES")),
        Row(label: "Plugin not installed", targetState: .wcpayNotInstalled),
        Row(label: "Plugin outdated", targetState: .wcpayUnsupportedVersion),
        Row(label: "Plugin not active", targetState: .wcpayNotActivated),
        Row(label: "WCPay not set up", targetState: .wcpaySetupNotCompleted),
        Row(label: "Test mode with live account", targetState: .wcpayInTestModeWithLiveStripeAccount),
        Row(label: "Account under review", targetState: .stripeAccountUnderReview),
        Row(label: "Account with pending requirements", targetState: .stripeAccountPendingRequirement(deadline: Date(timeIntervalSinceNow: 86400))),
        Row(label: "Account with overdue requirements", targetState: .stripeAccountOverdueRequirement),
        Row(label: "Account rejected", targetState: .stripeAccountRejected),
        Row(label: "Generic error", targetState: .genericError),
        Row(label: "No connection", targetState: .noConnectionError),
        Row(label: "Completed", targetState: .completed),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }

    func configureTableView() {
        tableView.registerNib(for: BasicTableViewCell.self)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        model.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Onboarding state"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BasicTableViewCell.reuseIdentifier, for: indexPath)
        let row = model[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = row.label
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = model[indexPath.row]
        let viewModel = InPersonPaymentsViewModel(fixedState: row.targetState)
        let controller = InPersonPaymentsViewController(viewModel: viewModel)
        show(controller, sender: self)
    }
}
