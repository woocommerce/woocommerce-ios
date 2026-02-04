import Foundation
import UIKit
import Yosemite

/// This view controller is used when a reader is currently connected. It assists
/// the merchant in updating and/or disconnecting from the reader, as needed.
///
final class CardReaderSettingsConnectedViewController: UIViewController, PaymentSettingsFlowViewModelPresenter {
    /// Main TableView
    ///
    private var tableView: UITableView

    /// ViewModel
    ///
    private var viewModel: BluetoothCardReaderSettingsConnectedViewModel

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    private let settingsAlerts = CardReaderSettingsAlerts()

    init?(viewModel: PaymentSettingsFlowPresentedViewModel) {
        guard let viewModel = viewModel as? BluetoothCardReaderSettingsConnectedViewModel else {
            return nil
        }
        self.viewModel = viewModel
        self.tableView = UITableView(frame: .zero, style: .grouped)

        super.init(nibName: nil, bundle: nil)
        configureViews()
    }

    private func configureViews() {
        viewModel.didUpdate = onViewModelDidUpdate
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tableView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tableView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        registerTableViewCells()
        configureNavigation()
        configureSections()
        configureTable()
    }

    override func viewWillDisappear(_ animated: Bool) {
        viewModel.didUpdate = nil
        super.viewWillDisappear(animated)
    }
}

// MARK: - View Configuration
//
private extension CardReaderSettingsConnectedViewController {
    func onViewModelDidUpdate() {
        configureSections()
        configureTable()
        configureUpdateView()
    }

    /// Set the title and back button.
    ///
    func configureNavigation() {
        title = Localization.title
    }

    /// Setup the sections in this table view
    ///
    func configureSections() {
        sections = [
            Section(title: nil,
                    rows: [
                        .updatePrompt
                    ]
            ),
            Section(title: Localization.sectionHeaderTitle,
                    rows: [
                        .connectedReader,
                        .updateButton,
                        .disconnectButton
                    ]
            )
        ]
    }

    func configureTable() {
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = .zero
        tableView.estimatedSectionHeaderHeight = .zero
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }

    func configureUpdateView() {
        let viewModel = viewModel // capture for closures

        if let error = viewModel.readerUpdateError {
            if case CardReaderServiceError.softwareUpdate(underlyingError: let underlyingError, batteryLevel: let batteryLevel) = error,
               underlyingError == .readerSoftwareUpdateFailedBatteryLow {
                settingsAlerts.updatingFailedLowBattery(from: self, batteryLevel: batteryLevel, retrySearch: {
                    viewModel.startCardReaderUpdate()
                }, close: { [settingsAlerts] in
                    settingsAlerts.dismiss()
                })
            } else {
                settingsAlerts.updatingFailed(
                    from: self,
                    tryAgain: {
                        viewModel.startCardReaderUpdate()
                    },
                    close: {
                        viewModel.dismissReaderUpdateError()
                    }
                )
            }
        } else if let readerUpdateProgress = viewModel.readerUpdateProgress {
            // If we are updating a reader, show the progress alert
            settingsAlerts.updateProgress(from: self,
                                          requiredUpdate: false,
                                          progress: readerUpdateProgress,
                                          cancel: viewModel.cancelCardReaderUpdate)
        } else {
            // If we are not updating a reader, dismiss any progress alert
            settingsAlerts.dismiss()
        }
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
        case let cell as LeftImageTableViewCell where row == .updatePrompt:
            configureUpdatePrompt(cell: cell)
        case let cell as ConnectedReaderTableViewCell where row == .connectedReader:
            configureConnectedReader(cell: cell)
        case let cell as ButtonTableViewCell where row == .updateButton:
            configureUpdateButton(cell: cell)
        case let cell as ButtonTableViewCell where row == .disconnectButton:
            configureDisconnectButton(cell: cell)
        default:
            fatalError()
        }
    }

    private func configureUpdatePrompt(cell: LeftImageTableViewCell) {
        let state = UpdatePromptState(viewModel: viewModel)
        cell.configure(image: .infoOutlineImage, text: state.text)
        cell.backgroundColor = state.backgroundColor
        cell.imageView?.tintColor = state.tintColor
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.textColor = .text
    }

    private func configureConnectedReader(cell: ConnectedReaderTableViewCell) {
        let cellViewModel = ConnectedReaderTableViewCell.ViewModel(
            name: viewModel.connectedReaderID,
            batteryLevel: viewModel.connectedReaderBatteryLevel,
            softwareVersion: viewModel.connectedReaderSoftwareVersion
        )
        cell.configure(viewModel: cellViewModel)
        cell.selectionStyle = .none
    }

    private func configureUpdateButton(cell: ButtonTableViewCell) {
        let style: ButtonTableViewCell.Style = viewModel.optionalReaderUpdateAvailable ? .primary : .secondary
        cell.configure(style: style, title: Localization.updateButtonTitle, bottomSpacing: 0) { [weak self] in
            self?.viewModel.startCardReaderUpdate()
        }

        let readerDisconnectInProgress = viewModel.readerDisconnectInProgress
        let readerUpdateInProgress = viewModel.readerUpdateInProgress
        let readerReconnectionInProgress = viewModel.readerReconnectionInProgress
        cell.enableButton(viewModel.optionalReaderUpdateAvailable &&
                          !readerDisconnectInProgress &&
                          !readerUpdateInProgress &&
                          !readerReconnectionInProgress)
        cell.showActivityIndicator(readerUpdateInProgress)

        cell.selectionStyle = .none
        cell.backgroundColor = .clear
    }

    private func configureDisconnectButton(cell: ButtonTableViewCell) {
        let state = DisconnectButtonState(viewModel: viewModel)
        cell.configure(style: state.style, title: state.title) { [weak self, state] in
            state.action(self?.viewModel)
        }
        cell.enableButton(state.isEnabled)
        cell.showActivityIndicator(state.showActivityIndicator)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
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
        return section == 0 ? CGFloat.leastNonzeroMagnitude : UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


// MARK: - Private Types
//
private struct Section {
    let title: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case updatePrompt
    case connectedReader
    case updateButton
    case disconnectButton

    var type: UITableViewCell.Type {
        switch self {
        case .updatePrompt:
            return LeftImageTableViewCell.self
        case .connectedReader:
            return ConnectedReaderTableViewCell.self
        case .updateButton:
            return ButtonTableViewCell.self
        case .disconnectButton:
            return ButtonTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

private enum UpdatePromptState {
    case reconnecting
    case updateAvailable
    case upToDate

    init(viewModel: BluetoothCardReaderSettingsConnectedViewModel) {
        switch (viewModel.readerReconnectionInProgress, viewModel.optionalReaderUpdateAvailable) {
        case (true, _):
            self = .reconnecting
        case (false, true):
            self = .updateAvailable
        case (false, false):
            self = .upToDate
        }
    }

    var text: String {
        switch self {
        case .reconnecting:
            return Localization.reconnectingText
        case .updateAvailable:
            return Localization.updatePromptText
        case .upToDate:
            return Localization.updateNotNeeded
        }
    }

    var backgroundColor: UIColor? {
        switch self {
        case .reconnecting, .updateAvailable:
            return .warningBackground
        case .upToDate:
            return .none
        }
    }

    var tintColor: UIColor {
        switch self {
        case .reconnecting, .updateAvailable:
            return .warning
        case .upToDate:
            return .info
        }
    }
}

private enum DisconnectButtonState {
    case reconnecting
    case cancellingReconnection
    case disconnecting
    case updating
    case idle(updateAvailable: Bool)

    init(viewModel: BluetoothCardReaderSettingsConnectedViewModel) {
        switch (viewModel.readerReconnectionCancellationInProgress,
                viewModel.readerReconnectionInProgress,
                viewModel.readerDisconnectInProgress,
                viewModel.readerUpdateInProgress) {
        case (true, _, _, _):
            self = .cancellingReconnection
        case (false, true, _, _):
            self = .reconnecting
        case (false, false, true, _):
            self = .disconnecting
        case (false, false, false, true):
            self = .updating
        case (false, false, false, false):
            self = .idle(updateAvailable: viewModel.optionalReaderUpdateAvailable)
        }
    }

    var title: String {
        switch self {
        case .reconnecting:
            return Localization.cancelReconnectionButtonTitle
        case .cancellingReconnection:
            return Localization.cancellingReconnectionButtonTitle
        case .disconnecting, .updating, .idle:
            return Localization.disconnectButtonTitle
        }
    }

    var style: ButtonTableViewCell.Style {
        switch self {
        case .reconnecting, .cancellingReconnection, .disconnecting, .updating:
            return .primary
        case .idle(let updateAvailable):
            return updateAvailable ? .secondary : .primary
        }
    }

    var isEnabled: Bool {
        switch self {
        case .reconnecting, .idle:
            return true
        case .cancellingReconnection, .disconnecting, .updating:
            return false
        }
    }

    var showActivityIndicator: Bool {
        switch self {
        case .cancellingReconnection, .disconnecting:
            return true
        case .reconnecting, .updating, .idle:
            return false
        }
    }

    func action(_ viewModel: BluetoothCardReaderSettingsConnectedViewModel?) {
        switch self {
        case .reconnecting:
            viewModel?.cancelReconnection()
        case .cancellingReconnection, .disconnecting, .updating:
            break
        case .idle:
            viewModel?.disconnectReader()
        }
    }
}

private typealias Localization = CardReaderSettingsConnectedViewController.Localization

// MARK: - Localization
//
private extension CardReaderSettingsConnectedViewController {
    enum Localization {
        static let title = NSLocalizedString(
            "Manage Card Reader",
            comment: "Settings > Manage Card Reader > Title for the reader connected screen in settings."
        )

        static let updatePromptText = NSLocalizedString(
            "Please update your reader software to keep accepting payments",
            comment: "Settings > Manage Card Reader > Connected Reader > A prompt to update a reader running older software"
        )

        static let updateNotNeeded = NSLocalizedString(
            "Congratulations! Your reader is running the latest software",
            comment: "Settings > Manage Card Reader > Connected Reader > A prompt to update a reader running older software"
        )

        static let sectionHeaderTitle = NSLocalizedString(
            "Connected Reader",
            comment: "Settings > Manage Card Reader > Connected Reader Table Section Heading"
        )

        static let updateButtonTitle = NSLocalizedString(
            "Update Reader Software",
            comment: "Settings > Manage Card Reader > Connected Reader > A button to update the reader software"
        )

        static let disconnectButtonTitle = NSLocalizedString(
            "Disconnect Reader",
            comment: "Settings > Manage Card Reader > Connected Reader > A button to disconnect the reader"
        )

        static let reconnectingText = NSLocalizedString(
            "cardReaderSettingsConnectedViewController.reconnectingText",
            value: "Reconnecting to card reader...",
            comment: "Settings > Manage Card Reader > Connected Reader > Status message when reader is reconnecting"
        )

        static let cancelReconnectionButtonTitle = NSLocalizedString(
            "cardReaderSettingsConnectedViewController.cancelReconnectionButtonTitle",
            value: "Cancel Reconnection",
            comment: "Settings > Manage Card Reader > Connected Reader > A button to cancel the reconnection attempt"
        )

        static let cancellingReconnectionButtonTitle = NSLocalizedString(
            "cardReaderSettingsConnectedViewController.cancellingReconnectionButtonTitle",
            value: "Cancelling...",
            comment: "Settings > Manage Card Reader > Connected Reader > Button title shown while cancellation is in progress"
        )

    }
}
