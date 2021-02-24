import UIKit

final class CardReaderSettingsConnectView: NSObject {

    private var rows = [Row]()

    var onPressedConnect: (() -> ())?

    override init() {
        super.init()
        rows = [.connectHeader, .connectImage, .connectHelp1, .connectHelp2, .connectHelp3, .connectButton, .connectLearnMore]
    }

    public func rowTypes() -> [UITableViewCell.Type] {
        return [
            ButtonTableViewCell.self,
            ImageTableViewCell.self,
            LearnMoreTableViewCell.self,
            NumberedListItemTableViewCell.self,
            TitleTableViewCell.self
        ]
    }

    private func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TitleTableViewCell where row == .connectHeader:
            configureHeader(cell: cell)
        case let cell as ImageTableViewCell where row == .connectImage:
            configureImage(cell: cell)
        case let cell as NumberedListItemTableViewCell where row == .connectHelp1:
            configureHelp1(cell: cell)
        case let cell as NumberedListItemTableViewCell where row == .connectHelp2:
            configureHelp2(cell: cell)
        case let cell as NumberedListItemTableViewCell where row == .connectHelp3:
            configureHelp3(cell: cell)
        case let cell as ButtonTableViewCell where row == .connectButton:
            configureButton(cell: cell)
        case let cell as LearnMoreTableViewCell where row == .connectLearnMore:
            configureLearnMore(cell: cell)
        default:
            fatalError()
        }
    }

    private func configureHeader(cell: TitleTableViewCell) {
        cell.titleLabel?.text = NSLocalizedString(
            "Connect your card reader",
            comment: "Settings > Manage Card Reader > Prompt user to connect their first reader"
        )
        cell.hideSeparator()
        cell.selectionStyle = .none
    }

    private func configureImage(cell: ImageTableViewCell) {
        cell.detailImageView?.image = UIImage(named: "card-reader-connect")
        cell.hideSeparator()
        cell.selectionStyle = .none
    }

    private func configureHelp1(cell: NumberedListItemTableViewCell) {
        cell.numberLabel?.text = NSLocalizedString(
            "1",
            comment: "Settings > Manage Card Reader > Connect > List item, number 1"
        )
        cell.itemTextLabel?.text = NSLocalizedString(
            "Make sure card reader is charged",
            comment: "Settings > Manage Card Reader > Connect > Help hint for connecting reader")
        cell.hideSeparator()
        cell.selectionStyle = .none
    }

    private func configureHelp2(cell: NumberedListItemTableViewCell) {
        cell.numberLabel?.text = NSLocalizedString(
            "2",
            comment: "Settings > Manage Card Reader > Connect > List item, number 2"
        )
        cell.itemTextLabel?.text = NSLocalizedString(
            "Turn card reader on and place it next to mobile device",
            comment: "Settings > Manage Card Reader > Connect > Help hint for connecting reader")
        cell.hideSeparator()
        cell.selectionStyle = .none
    }

    private func configureHelp3(cell: NumberedListItemTableViewCell) {
        cell.numberLabel?.text = NSLocalizedString(
            "3",
            comment: "Settings > Manage Card Reader > Connect > List item, number 3"
        )
        cell.itemTextLabel?.text = NSLocalizedString(
            "Turn mobile device Bluetooth on",
            comment: "Settings > Manage Card Reader > Connect > Help hint for connecting reader")
        cell.hideSeparator()
        cell.selectionStyle = .none
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
        cell.selectionStyle = .none
    }

    private func configureLearnMore(cell: LearnMoreTableViewCell) {
        cell.learnMoreLabel.text = NSLocalizedString(
            "Learn more about accepting payments with your mobile device and ordering card readers",
            comment: "Settings > Manage Card Reader > Connect > A prompt for new users to start accepting mobile payments"
        )
        cell.hideSeparator()
        cell.selectionStyle = .none
    }
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
            return TitleTableViewCell.self
        case .connectImage:
            return ImageTableViewCell.self
        case .connectHelp1:
            return NumberedListItemTableViewCell.self
        case .connectHelp2:
            return NumberedListItemTableViewCell.self
        case .connectHelp3:
            return NumberedListItemTableViewCell.self
        case .connectButton:
            return ButtonTableViewCell.self
        case .connectLearnMore:
            return LearnMoreTableViewCell.self
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
extension CardReaderSettingsConnectView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rowAtIndexPath(indexPath)
        if row == .connectImage {
            return 250
        }
        if row == .connectHelp1 || row == .connectHelp2 || row == .connectHelp3 {
            return 70
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = rowAtIndexPath(indexPath)
        if row == .connectLearnMore {
            guard let url = URL(string: "https://woocommerce.com/payments/") else {
                return
            }
            UIApplication.shared.open(url)
        }
    }
}
