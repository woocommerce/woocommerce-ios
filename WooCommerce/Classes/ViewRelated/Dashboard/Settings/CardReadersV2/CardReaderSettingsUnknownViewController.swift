import Foundation
import UIKit

/// This view controller is used when no readers are known or connected. It assists
/// the merchant in connecting to a reader, often for the first time.
///
final class CardReaderSettingsUnknownViewController: UIViewController, CardReaderSettingsViewModelPresenter {

    /// Main TableView
    ///
    @IBOutlet weak var tableView: UITableView!

    /// ViewModel
    ///
    private var viewModel: CardReaderSettingsUnknownViewModel?

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    /// Alert modal, if any
    ///
    private var alert: UIAlertController?

    /// Accept our viewmodel and listen for changes on it
    ///
    func configure(viewModel: CardReaderSettingsPresentedViewModel) {
        self.viewModel = viewModel as? CardReaderSettingsUnknownViewModel

        guard self.viewModel != nil else {
            DDLogError("Unexpectedly unable to downcast to CardReaderSettingsUnknownViewModel")
            return
        }

        self.viewModel?.didUpdate = onViewModelDidUpdate
    }

    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        registerTableViewCells()
        configureNavigation()
        configureSections()
        configureTable()
    }

    /// We're disappearing... stop listening to viewmodel changes to avoid a reference loop
    /// and close any modal
    ///
    override func viewWillDisappear(_ animated: Bool) {
        viewModel?.didUpdate = nil
        alert?.dismiss(animated: false, completion: nil)
        super.viewWillDisappear(animated)
    }
}

// MARK: - View Updates
//
private extension CardReaderSettingsUnknownViewController {
    func onViewModelDidUpdate() {
        updateModal()
        updateTable()
    }

    func updateModal() {
        guard let viewModel = viewModel else {
            return
        }

        /// Dismiss any pre-existing modal
        alert?.dismiss(animated: true, completion: nil)

        if viewModel.discoveryState == .searching {
            showSearchingModal()
        }
    }

    func updateTable() {
        tableView.reloadData()
    }

    func showSearchingModal() {
        // TODO - replace with new, richer modals once they stabilize
        alert = UIAlertController(
            title: Localization.searchModalTitle,
            message: Localization.searchModalSubtitle,
            preferredStyle: UIAlertController.Style.alert
        )
        let cancelAction = UIAlertAction(title: Localization.searchModalCancelButton, style: .cancel) { UIAlertAction in
            self.viewModel?.cancelReaderDiscovery()
        }
        alert?.addAction(cancelAction)
        if alert != nil {
            present(alert!, animated: true, completion: nil)
        }
    }
}

// MARK: - View Configuration
//
private extension CardReaderSettingsUnknownViewController {

    /// Set the title.
    ///
    func configureNavigation() {
        title = Localization.title
    }

    /// Setup the sections in this table view
    ///
    func configureSections() {
        sections = [Section(title: nil,
                            rows: [
                                .connectHeader,
                                .connectImage,
                                .connectHelpHintChargeReader,
                                .connectHelpHintTurnOnReader,
                                .connectHelpHintEnableBluetooth,
                                .connectButton,
                                .connectLearnMore
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
        case let cell as TitleTableViewCell where row == .connectHeader:
            configureHeader(cell: cell)
        case let cell as ImageTableViewCell where row == .connectImage:
            configureImage(cell: cell)
        case let cell as NumberedListItemTableViewCell where row == .connectHelpHintChargeReader:
            configureHelpHintChargeReader(cell: cell)
        case let cell as NumberedListItemTableViewCell where row == .connectHelpHintTurnOnReader:
            configureHelpHintTurnOnReader(cell: cell)
        case let cell as NumberedListItemTableViewCell where row == .connectHelpHintEnableBluetooth:
            configureHelpHintEnableBluetooth(cell: cell)
        case let cell as ButtonTableViewCell where row == .connectButton:
            configureButton(cell: cell)
        case let cell as LearnMoreTableViewCell where row == .connectLearnMore:
            configureLearnMore(cell: cell)
        default:
            fatalError()
        }
    }

    private func configureHeader(cell: TitleTableViewCell) {
        cell.titleLabel?.text = Localization.connectYourCardReaderTitle
        cell.selectionStyle = .none
    }

    private func configureImage(cell: ImageTableViewCell) {
        cell.detailImageView?.image = UIImage(named: "card-reader-connect")
        cell.selectionStyle = .none
    }

    private func configureHelpHintChargeReader(cell: NumberedListItemTableViewCell) {
        cell.numberLabel?.text = Localization.hintOneTitle
        cell.itemTextLabel?.text = Localization.hintOne
        cell.selectionStyle = .none
    }

    private func configureHelpHintTurnOnReader(cell: NumberedListItemTableViewCell) {
        cell.numberLabel?.text = Localization.hintTwoTitle
        cell.itemTextLabel?.text = Localization.hintTwo
        cell.selectionStyle = .none
    }

    private func configureHelpHintEnableBluetooth(cell: NumberedListItemTableViewCell) {
        cell.numberLabel?.text = Localization.hintThreeTitle
        cell.itemTextLabel?.text = Localization.hintThree
        cell.selectionStyle = .none
   }

    private func configureButton(cell: ButtonTableViewCell) {
        let buttonTitle = Localization.connectButton
        cell.configure(title: buttonTitle) {
            self.viewModel?.startReaderDiscovery()
        }
        cell.selectionStyle = .none
    }

    private func configureLearnMore(cell: LearnMoreTableViewCell) {
        cell.learnMoreLabel.text = Localization.learnMore
        cell.selectionStyle = .none
    }
}

// MARK: - Convenience Methods
//
private extension CardReaderSettingsUnknownViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension CardReaderSettingsUnknownViewController: UITableViewDataSource {

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
extension CardReaderSettingsUnknownViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rowAtIndexPath(indexPath)
        return row.height
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // TODO: Connect the connect button to the view model
    }
}

// MARK: - Private Types
//
private struct Section {
    let title: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case connectHeader
    case connectImage
    case connectHelpHintChargeReader
    case connectHelpHintTurnOnReader
    case connectHelpHintEnableBluetooth
    case connectButton
    case connectLearnMore

    var type: UITableViewCell.Type {
        switch self {
        case .connectHeader:
            return TitleTableViewCell.self
        case .connectImage:
            return ImageTableViewCell.self
        case .connectHelpHintChargeReader:
            return NumberedListItemTableViewCell.self
        case .connectHelpHintTurnOnReader:
            return NumberedListItemTableViewCell.self
        case .connectHelpHintEnableBluetooth:
            return NumberedListItemTableViewCell.self
        case .connectButton:
            return ButtonTableViewCell.self
        case .connectLearnMore:
            return LearnMoreTableViewCell.self
        }
    }

    var height: CGFloat {
        switch self {
        case .connectHeader,
             .connectButton,
             .connectImage:
            return UITableView.automaticDimension
        case .connectHelpHintChargeReader,
             .connectHelpHintTurnOnReader,
             .connectHelpHintEnableBluetooth,
             .connectLearnMore:
            return 70
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

// MARK: - Localization
//
private extension CardReaderSettingsUnknownViewController {
    enum Localization {
        static let title = NSLocalizedString(
            "Manage Card Reader",
            comment: "Settings > Manage Card Reader > Title for the no-reader-connected screen in settings."
        )

        static let connectYourCardReaderTitle = NSLocalizedString(
            "Connect your card reader",
            comment: "Settings > Manage Card Reader > Prompt user to connect their first reader"
        )

        static let hintOneTitle = NSLocalizedString(
            "1",
            comment: "Settings > Manage Card Reader > Connect > Help hint number 1"
        )

        static let hintOne = NSLocalizedString(
            "Make sure card reader is charged",
            comment: "Settings > Manage Card Reader > Connect > Hint to charge card reader"
        )

        static let hintTwoTitle = NSLocalizedString(
            "2",
            comment: "Settings > Manage Card Reader > Connect > Help hint number 2"
        )

        static let hintTwo = NSLocalizedString(
            "Turn card reader on and place it next to mobile device",
            comment: "Settings > Manage Card Reader > Connect > Hint to power on reader"
        )

        static let hintThreeTitle = NSLocalizedString(
            "3",
            comment: "Settings > Manage Card Reader > Connect > Help hint number 3"
        )

        static let hintThree = NSLocalizedString(
            "Turn mobile device Bluetooth on",
            comment: "Settings > Manage Card Reader > Connect > Hint to enable Bluetooth"
        )

        static let connectButton = NSLocalizedString(
            "Connect Card Reader",
            comment: "Settings > Manage Card Reader > Connect > A button to begin a search for a reader"
        )

        static let learnMore = NSLocalizedString(
            "Learn more about accepting payments with your mobile device and ordering card readers",
            comment: "Settings > Manage Card Reader > Connect > A prompt for new users to start accepting mobile payments"
        )

        static let searchModalTitle = NSLocalizedString(
            "Scanning for readers",
            comment: "Title for the modal dialog that appears when searching for a card reader"
        )

        static let searchModalSubtitle = NSLocalizedString(
            "Turn on your reader by pressing its power button",
            comment: "Subtitle for the modal dialog that appears when searching for a card reader"
        )

        static let searchModalCancelButton = NSLocalizedString(
            "Cancel",
            comment: "Label for a cancel button"
        )
    }
}
