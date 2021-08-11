import UIKit
import SwiftUI

final class InPersonPaymentsMenuViewController: UITableViewController {
    private var rows = [Row]()

    init() {
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureRows()
        configureTableView()
        registerTableViewCells()
    }
}

// MARK: - View configuration
//
private extension InPersonPaymentsMenuViewController {

    func configureRows() {
        rows = [
            .orderCardReader,
            .manageCardReader
        ]
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as BasicTableViewCell where row == .orderCardReader:
            configureOrderCardReader(cell: cell)
        case let cell as BasicTableViewCell where row == .manageCardReader:
            configureManageCardReader(cell: cell)
        default:
            fatalError()
        }
    }

    func configureOrderCardReader(cell: UITableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Order card reader", comment: "Navigates to Card Reader ordering screen")
    }

    func configureManageCardReader(cell: UITableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Manage card reader", comment: "Navigates to Card Reader management screen")
    }
}

// MARK: - Convenience methods
//
private extension InPersonPaymentsMenuViewController {
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        rows[indexPath.row]
    }
}

// MARK: - Actions
//
extension InPersonPaymentsMenuViewController {
    func orderCardReaderWasPressed() {
        WebviewHelper.launch(Constants.woocommercePurchaseCardReaderURL, with: self)
    }

    func manageCardReaderWasPressed() {
        ServiceLocator.analytics.track(.settingsCardReadersTapped)
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: CardReaderSettingsPresentingViewController.self) else {
            fatalError("Cannot instantiate `CardReaderSettingsPresentingViewController` from Dashboard storyboard")
        }

        let viewModelsAndViews = CardReaderSettingsViewModelsOrderedList()
        viewController.configure(viewModelsAndViews: viewModelsAndViews)
        show(viewController, sender: self)
    }
}

// MARK: - UITableViewDataSource
extension InPersonPaymentsMenuViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate
//
extension InPersonPaymentsMenuViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // listed in the order they are displayed
        switch rowAtIndexPath(indexPath) {
        case .orderCardReader:
            orderCardReaderWasPressed()
        case .manageCardReader:
            manageCardReaderWasPressed()
        }
    }
}

private enum Row: CaseIterable {
    case orderCardReader
    case manageCardReader
    var type: UITableViewCell.Type {
        switch self {
        case .orderCardReader:
            return BasicTableViewCell.self
        case .manageCardReader:
            return BasicTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

private enum Constants {
    static let woocommercePurchaseCardReaderURL = URL(string: "https://woocommerce.com/products/bbpos-chipper2xbt-card-reader")!
}

// MARK: - SwiftUI compatibility
//

/// SwiftUI wrapper for CardReaderSettingsPresentingViewController
///
struct InPersonPaymentsMenu: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        InPersonPaymentsMenuViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}
