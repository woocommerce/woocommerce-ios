import UIKit

/// Presents a tracking provider, tracking number and shipment date
///
final class AddTrackingViewController: UIViewController {

    @IBOutlet private weak var table: UITableView!

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        table.reloadData()
    }
}


private extension AddTrackingViewController {
    func configureNavigation() {
        configureTitle()
        configureDismissButton()
        configureAddButton()
        configureSections()
    }

    func configureTitle() {
        title = NSLocalizedString("Add Tracking",
            comment: "Add tracking screen - title.")
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

    func configureAddButton() {
        let addButtonTitle = NSLocalizedString("Add",
                                               comment: "Add tracking screen - button title to add a tracking")
        let rightBarButton = UIBarButtonItem(title: addButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(addButtonTapped))
        rightBarButton.tintColor = .white
        navigationItem.setRightBarButton(rightBarButton, animated: false)
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func addButtonTapped() {
        print("=== add===")
    }
}


private extension AddTrackingViewController {
    func configureTable() {
        registerTableViewCells()
        configureSections()

        table.estimatedRowHeight = Constants.rowHeight
        table.rowHeight = UITableView.automaticDimension
        table.backgroundColor = StyleManager.tableViewBackgroundColor
        table.dataSource = self
        table.delegate = self
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            table.register(row.type.loadNib(),
                           forCellReuseIdentifier: row.reuseIdentifier)
        }
    }

    func configureSections() {
        let trackingRows: [Row] = [.shippingProvider,
                                   .trackingNumber,
                                   .dateShipped]

        sections = [
            Section(rows: trackingRows),
            Section(rows: [.deleteTracking])]
    }
}


extension AddTrackingViewController: UITableViewDataSource {
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
    fileprivate func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as EditableValueOneTableViewCell where row == .shippingProvider:
            configureShippingProvider(cell: cell)
        case let cell as EditableValueOneTableViewCell where row == .trackingNumber:
            configureTrackingNumber(cell: cell)
        case let cell as EditableValueOneTableViewCell where row == .dateShipped:
            configureDateShipped(cell: cell)
        case let cell as BasicTableViewCell where row == .deleteTracking:
            configureDeleteTracking(cell: cell)
        default:
            fatalError()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    private func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    private func configureShippingProvider(cell: EditableValueOneTableViewCell) {
        cell.title.text = NSLocalizedString("Shipping provider", comment: "Add / Edit shipping provider. Title of cell presenting name")

        cell.value.isEnabled = false
        cell.accessoryType = .disclosureIndicator
    }

    private func configureTrackingNumber(cell: EditableValueOneTableViewCell) {
        cell.title.text = NSLocalizedString("Tracking number", comment: "Add / Edit shipping provider. Title of cell presenting tracking number")
        cell.value.isEnabled = true

        let camera = UIImageView(image: .cameraImage)
        cell.accessoryView = camera
    }

    private func configureDateShipped(cell: EditableValueOneTableViewCell) {
        cell.title.text = NSLocalizedString("Date shipped", comment: "Add / Edit shipping provider. Title of cell date shipped")

        cell.value.isEnabled = true
        cell.accessoryType = .none
    }

    func configureDeleteTracking(cell: BasicTableViewCell) {
        cell.selectionStyle = .default
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = StyleManager.destructiveActionColor
        cell.textLabel?.text = NSLocalizedString("Delete Tracking", comment: "Delete Tracking button title")
    }
}

extension AddTrackingViewController: UITableViewDelegate {
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
private extension AddTrackingViewController {
    func executeAction(for row: Row) {
        if row == .deleteTracking {
            deleteCurrentTracking()
        }

        if row == .shippingProvider {
            showAllShipmentProviders()
        }
    }

    func deleteCurrentTracking() {
        //
    }

    func showAllShipmentProviders() {
        print("=== showing all shipment providers ====")
    }
}


private struct Section {
    let rows: [Row]
}


private enum Row: CaseIterable {
    case shippingProvider
    case trackingNumber
    case dateShipped
    case deleteTracking

    var type: UITableViewCell.Type {
        switch self {
        case .shippingProvider:
            return EditableValueOneTableViewCell.self
        case .trackingNumber:
            return EditableValueOneTableViewCell.self
        case .dateShipped:
            return EditableValueOneTableViewCell.self
        case .deleteTracking:
            return BasicTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}


private struct Constants {
    static let rowHeight = CGFloat(74)
}
