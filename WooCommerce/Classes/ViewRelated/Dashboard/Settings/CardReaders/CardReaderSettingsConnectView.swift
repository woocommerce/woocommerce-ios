import UIKit

final class CardReaderSettingsConnectView: NSObject {

    private var rows = [Row]()

    var onPressedConnect: (() -> ())?

    override init() {
        super.init()
        rows = [.connectHeader, .connectImage, .connectHelp1, .connectHelp2, .connectHelp3, .connectButton, .connectLearnMore]
    }

    private func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as BasicTableViewCell where row == .connectHeader:
            configureHeader(cell: cell)
        case let cell as BasicTableViewCell where row == .connectImage:
            configureImage(cell: cell)
        case let cell as BasicTableViewCell where row == .connectHelp1:
            configureHelp1(cell: cell)
        case let cell as BasicTableViewCell where row == .connectHelp2:
            configureHelp2(cell: cell)
        case let cell as BasicTableViewCell where row == .connectHelp3:
            configureHelp3(cell: cell)
        case let cell as ButtonTableViewCell where row == .connectButton:
            configureButton(cell: cell)
        case let cell as BasicTableViewCell where row == .connectLearnMore:
            configureLearnMore(cell: cell)
        default:
            fatalError()
        }
    }

    private func configureHeader(cell: BasicTableViewCell) {
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .listForeground
        cell.textLabel?.text = NSLocalizedString(
            "Connect your card reader",
            comment: "Settings > Manage Card Reader > Prompt user to connect their first reader"
        )
        cell.hideSeparator()
        cell.textLabel?.numberOfLines = 0
    }

    private func configureImage(cell: BasicTableViewCell) {
        cell.imageView?.image = UIImage(named: "card-reader-connect")
        cell.imageView?.tintColor = .listForeground
        cell.textLabel?.text = NSLocalizedString(
            "Connect your card reader",
            comment: "Settings > Manage Card Reader > Connect > An illustration of connecting a card reader"
        )
        cell.hideSeparator()
        cell.textLabel?.numberOfLines = 0
    }

    private func configureHelp1(cell: BasicTableViewCell) {
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .listForeground
        cell.textLabel?.text = NSLocalizedString(
            "Make sure card reader is charged",
            comment: "Settings > Manage Card Reader > Connect > One of three hints to help the user connect their reader"
        )
        cell.hideSeparator()
        cell.textLabel?.numberOfLines = 0
    }

    private func configureHelp2(cell: BasicTableViewCell) {
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .listForeground
        cell.textLabel?.text = NSLocalizedString(
            "Turn card reader on and place it next to mobile device",
            comment: "Settings > Manage Card Reader > Connect > One of three hints to help the user connect their reader"
        )
        cell.hideSeparator()
        cell.textLabel?.numberOfLines = 0
    }

    private func configureHelp3(cell: BasicTableViewCell) {
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .listForeground
        cell.textLabel?.text = NSLocalizedString(
            "Turn mobile device bluetooth on",
            comment: "Settings > Manage Card Reader > Connect > One of three hints to help the user connect their reader"
        )
        cell.hideSeparator()
        cell.textLabel?.numberOfLines = 0
    }

    private func configureButton(cell: ButtonTableViewCell) {
        let buttonTitle = NSLocalizedString(
            "Connect card reader",
            comment: "Settings > Manage Card Reader > Connect > A button to begin a search for a reader"
        )
        cell.configure(title: buttonTitle) { [weak self] in
            self?.onPressedConnect?()
        }
        cell.hideSeparator()
    }

    private func configureLearnMore(cell: BasicTableViewCell) {
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .listForeground
        cell.textLabel?.text = NSLocalizedString(
            "Learn more about accepting payments with your mobile device and ordering card readers",
            comment: "Settings > Manage Card Reader > Connect > A prompt for new users to start accepting mobile payments"
        )
        cell.hideSeparator()
        cell.textLabel?.numberOfLines = 0
    }
}

private struct Section {
    let title: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case connectHeader
    case connectImage
    case connectHelp1
    case connectHelp2
    case connectHelp3
    case connectButton
    case connectLearnMore

    var type: UITableViewCell.Type {
        switch self {
        case .connectHeader:
            return BasicTableViewCell.self
        case .connectImage:
            return BasicTableViewCell.self
        case .connectHelp1:
            return BasicTableViewCell.self
        case .connectHelp2:
            return BasicTableViewCell.self
        case .connectHelp3:
            return BasicTableViewCell.self
        case .connectButton:
            return ButtonTableViewCell.self
        case .connectLearnMore:
            return BasicTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

// MARK: - Convenience Methods
//
private extension CardReaderSettingsConnectView {
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return rows[indexPath.row]
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension CardReaderSettingsConnectView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
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

extension CardReaderSettingsConnectView: UITableViewDelegate {
}
