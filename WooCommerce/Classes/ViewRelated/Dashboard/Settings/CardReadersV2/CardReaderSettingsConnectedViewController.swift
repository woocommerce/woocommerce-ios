import Foundation
import UIKit

/// This view controller is used when a reader is currently connected. It assists
/// the merchant in updating and/or disconnecting from the reader, as needed.
///
final class CardReaderSettingsConnectedViewController: UIViewController, CardReaderSettingsViewModelPresenter {

    /// Main TableView
    ///
    @IBOutlet weak private var tableView: UITableView!

    /// ViewModel
    ///
    private var viewModel: CardReaderSettingsConnectedViewModel?

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    /// Accept our viewmodel
    ///
    func configure(viewModel: CardReaderSettingsPresentedViewModel) {
        self.viewModel = viewModel as? CardReaderSettingsConnectedViewModel

        guard self.viewModel != nil else {
            DDLogError("Unexpectedly unable to downcast to CardReaderSettingsConnectedViewModel")
            return
        }
    }

    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        registerTableViewCells()
        configureNavigation()
        configureSections()
        configureTable()
    }
}

// MARK: - View Configuration
//
private extension CardReaderSettingsConnectedViewController {

    /// Set the title and back button.
    ///
    func configureNavigation() {
        title = Localization.title
    }

    /// Setup the sections in this table view
    ///
    func configureSections() {
        sections = [Section(title: Localization.sectionHeaderTitle.uppercased(),
                            rows: [
                                .connectedReader,
                                .disconnectButton
                            ])]
    }

    func configureTable() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }

    /// Register table cells.
    ///
    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as ConnectedReaderTableViewCell where row == .connectedReader:
            configureConnectedReader(cell: cell)
        case let cell as ButtonTableViewCell where row == .disconnectButton:
            configureButton(cell: cell)
        default:
            fatalError()
        }
    }

    private func configureConnectedReader(cell: ConnectedReaderTableViewCell) {
        cell.serialNumberLabel?.text = viewModel?.connectedReaderSerialNumber
        cell.batteryLevelLabel?.text = viewModel?.connectedReaderBatteryLevel
        cell.selectionStyle = .none
    }

    private func configureButton(cell: ButtonTableViewCell) {
        cell.configure(title: Localization.buttonTitle) { [weak self] in
            self?.viewModel?.disconnectReader()
        }
        cell.selectionStyle = .none
    }
}

// MARK: - Convenience Methods
//
private extension CardReaderSettingsConnectedViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension CardReaderSettingsConnectedViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension CardReaderSettingsConnectedViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rowAtIndexPath(indexPath)
        return row.height
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // TODO: Connect the disconnect button to the view model
    }
}

// MARK: - Private Types
//
private struct Section {
    let title: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case connectedReader
    case disconnectButton

    var type: UITableViewCell.Type {
        switch self {
        case .connectedReader:
            return ConnectedReaderTableViewCell.self
        case .disconnectButton:
            return ButtonTableViewCell.self
        }
    }

    var height: CGFloat {
        switch self {
        case .connectedReader:
            return 60
        case .disconnectButton:
            return UITableView.automaticDimension
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

// MARK: - Localization
//
private extension CardReaderSettingsConnectedViewController {
    enum Localization {
        static let title = NSLocalizedString(
            "Manage Card Reader",
            comment: "Settings > Manage Card Reader > Title for the reader connected screen in settings."
        )

        static let sectionHeaderTitle = NSLocalizedString(
            "Connected Reader",
            comment: "Settings > Manage Card Reader > Connected Reader Table Section Heading"
        )

        static let buttonTitle = NSLocalizedString(
            "Disconnect",
            comment: "Settings > Manage Card Reader > Connected Reader > A button to disconnect the reader"
        )
    }
}
