import UIKit
import Yosemite

final class CardReaderSettingsConnectedReaderView: NSObject {
    var viewModel = CardReaderViewModel()
    var onPressedDisconnect: (() -> ())?

    private var rows = [Row]()

    override init() {
        super.init()
        rows = [
            .connectedReader,
            .disconnectButton
        ]
    }

    public func rowTypes() -> [UITableViewCell.Type] {
        return [
            ConnectedReaderTableViewCell.self,
            ButtonTableViewCell.self
        ]
    }

    private func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
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
        cell.serialNumberLabel?.text = viewModel.displayName
        cell.batteryLevelLabel?.text = viewModel.batteryStatus
        cell.selectionStyle = .none
    }

    private func configureButton(cell: ButtonTableViewCell) {
        let buttonTitle = NSLocalizedString(
            "Disconnect",
            comment: "Settings > Manage Card Reader > Connected Reader > A button to disconnect the reader"
        )
        cell.configure(title: buttonTitle) { [weak self] in
            self?.onPressedDisconnect?()
        }
        cell.selectionStyle = .none
    }
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

// MARK: - Convenience Methods
//
private extension CardReaderSettingsConnectedReaderView {
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return rows[indexPath.row]
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension CardReaderSettingsConnectedReaderView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionHeaderTitle = NSLocalizedString(
            "Connected Reader",
            comment: "Settings > Manage Card Reader > Connected Reader Table Section Heading"
        )
        return sectionHeaderTitle.uppercased()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension CardReaderSettingsConnectedReaderView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rowAtIndexPath(indexPath)
        return row.height
    }}
