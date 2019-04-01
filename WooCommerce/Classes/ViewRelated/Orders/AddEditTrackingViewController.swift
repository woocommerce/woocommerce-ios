import UIKit
import Yosemite
import Storage

/// Presents a tracking provider, tracking number and shipment date
///
final class AddEditTrackingViewController: UIViewController {
    private var viewModel: AddEditTrackingViewModel

    @IBOutlet private weak var table: UITableView!

    /// Table Sections to be rendered
    ///
    private lazy var sections = {
        return self.viewModel.sections
    }()

    init(viewModel: AddEditTrackingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        table.reloadData()
        activateActionButtonIfNecessary()
    }
}


private extension AddEditTrackingViewController {
    func configureNavigation() {
        configureTitle()
        configureDismissButton()
        configureBackButton()
        configureAddButton()
    }

    func configureTitle() {
        title = viewModel.title
    }

    func configureDismissButton() {
        let dismissButtonTitle = NSLocalizedString("Dismiss",
                                                   comment: "Add a note screen - button title for closing the view")
        let leftBarButton = UIBarButtonItem(title: dismissButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(dismissButtonTapped))
        leftBarButton.tintColor = .white
        navigationItem.setLeftBarButton(leftBarButton, animated: false)
    }

    func configureBackButton() {
        // Don't show the About title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }

    func configureAddButton() {
        let rightBarButton = UIBarButtonItem(title: viewModel.primaryActionTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(primaryButtonTapped))
        rightBarButton.tintColor = .white
        navigationItem.setRightBarButton(rightBarButton, animated: false)
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func primaryButtonTapped() {
//        let action = ShipmentAction.addTracking(siteID: <#T##Int#>, orderID: <#T##Int#>, providerGroupName: <#T##String#>, providerName: <#T##String#>, trackingNumber: <#T##String#>, onCompletion: <#T##(Error?) -> Void#>)
    }
}


private extension AddEditTrackingViewController {
    func configureTable() {
        registerTableViewCells()

        table.estimatedRowHeight = Constants.rowHeight
        table.rowHeight = UITableView.automaticDimension
        table.backgroundColor = StyleManager.tableViewBackgroundColor
        table.dataSource = self
        table.delegate = self
    }

    func registerTableViewCells() {
        viewModel.registerCells(for: table)
    }
}


extension AddEditTrackingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }

    /// Cells currently configured in the order they appear on screen
    ///
    fileprivate func configure(_ cell: UITableViewCell, for row: AddEditTrackingRow, at indexPath: IndexPath) {
        switch cell {
        case let cell as EditableValueOneTableViewCell where row == .shippingProvider:
            configureShippingProvider(cell: cell)
        case let cell as EditableValueOneTableViewCell where row == .trackingNumber:
            configureTrackingNumber(cell: cell)
        case let cell as EditableValueOneTableViewCell where row == .dateShipped:
            configureDateShipped(cell: cell)
        case let cell as BasicTableViewCell where row == .deleteTracking:
            configureSecondaryAction(cell: cell)
        default:
            fatalError()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    private func rowAtIndexPath(_ indexPath: IndexPath) -> AddEditTrackingRow {
        return sections[indexPath.section].rows[indexPath.row]
    }

    private func configureShippingProvider(cell: EditableValueOneTableViewCell) {
        cell.title.text = NSLocalizedString("Shipping provider", comment: "Add / Edit shipping provider. Title of cell presenting name")
        cell.value.text = viewModel.providerCellName

        cell.value.isEnabled = false
        cell.accessoryType = .disclosureIndicator
    }

    private func configureTrackingNumber(cell: EditableValueOneTableViewCell) {
        cell.title.text = NSLocalizedString("Tracking number", comment: "Add / Edit shipping provider. Title of cell presenting tracking number")
        cell.value.isEnabled = true

        cell.value.addTarget(self, action: #selector(didChangeTrackingNumber), for: .editingChanged)
        cell.accessoryType = .none
    }

    private func configureDateShipped(cell: EditableValueOneTableViewCell) {
        cell.title.text = NSLocalizedString("Date shipped", comment: "Add / Edit shipping provider. Title of cell date shipped")

        cell.value.text = viewModel.shipmentDate.toString(dateStyle: .medium, timeStyle: .none)

        cell.value.isEnabled = true
        cell.accessoryType = .none
    }

    func configureSecondaryAction(cell: BasicTableViewCell) {
        cell.selectionStyle = .default
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = StyleManager.destructiveActionColor
        cell.textLabel?.text = viewModel.secondaryActionTitle
    }
}

extension AddEditTrackingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let lastSection = sections.count - 1
        if section == lastSection {
            return UITableView.automaticDimension
        }
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = rowAtIndexPath(indexPath)
        executeAction(for: row)
    }
}


/// Execute user selection
///
private extension AddEditTrackingViewController {
    func executeAction(for row: AddEditTrackingRow) {
        viewModel.executeAction(for: row, sender: self)
    }
}


/// Tracking number textfield
///
private extension AddEditTrackingViewController {
    @objc func didChangeTrackingNumber(sender: UITextField) {
        guard let newTrackingNumber = sender.text else {
            return
        }

        viewModel.trackingNumber = newTrackingNumber
        activateActionButtonIfNecessary()
    }
}


/// Activates the action button (Add/Edit) if there is anough data to add or edit a shipment tracking
private extension AddEditTrackingViewController {
    private func activateActionButtonIfNecessary() {
        navigationItem.rightBarButtonItem?.isEnabled = viewModel.canCommit
    }
}


private struct Constants {
    static let rowHeight = CGFloat(74)
}
