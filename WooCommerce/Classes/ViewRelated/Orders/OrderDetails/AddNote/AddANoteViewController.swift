import UIKit
import Yosemite
import Gridicons
import CocoaLumberjack

class AddANoteViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet var tableView: UITableView!

    var viewModel: OrderDetailsViewModel!

    private var sections = [Section]()

    private var isCustomerNote = false

    private var noteText: String = ""

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTableView()
        registerTableViewCells()
        loadSections()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.firstSubview(ofType: UITextView.self)?.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    func configureNavigation() {
        title = NSLocalizedString("Order #\(viewModel.order.number)", comment: "Add a note screen - title. Example: Order #15")

        let dismissButtonTitle = NSLocalizedString("Dismiss", comment: "Add a note screen - button title for closing the view")
        let leftBarButton = UIBarButtonItem(title: dismissButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(dismissButtonTapped))
        leftBarButton.tintColor = .white
        navigationItem.setLeftBarButton(leftBarButton, animated: false)

        let addButtonTitle = NSLocalizedString("Add", comment: "Add a note screen - button title to send the note")
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
        let action = OrderNoteAction.addOrderNote(siteID: viewModel.order.siteID, orderID: viewModel.order.orderID, isCustomerNote: isCustomerNote, note: noteText) { [weak self] (orderNote, error) in
            if let error = error {
                DDLogError("⛔️ Error adding a note: \(error.localizedDescription)")
                // TODO: should this alert the user that there was an error?
                return
            }
            self?.dismiss(animated: true, completion: nil)
        }

        StoresManager.shared.dispatch(action)
    }
}

// MARK: - TableView Configuration
//
private extension AddANoteViewController {
    /// Setup: TableView
    ///
    private func configureTableView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    /// Registers all of the available TableViewCells
    ///
    private func registerTableViewCells() {
        let cells = [
            TextViewTableViewCell.self,
            SwitchTableViewCell.self
        ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    /// Setup: Sections
    ///
    private func loadSections() {
        let writeNoteSectionTitle = NSLocalizedString("WRITE NOTE", comment: "Add a note screen - Write Note section title")
        let writeNoteSection = Section(title: writeNoteSectionTitle, rows: [.writeNote])
        let emailCustomerSection = Section(title: nil, rows: [.emailCustomer])

        sections = [writeNoteSection, emailCustomerSection]
    }

    /// Switch between a private note and a customer note
    ///
    func toggleNoteType() {
        isCustomerNote = !isCustomerNote
    }

    /// Cell Configuration
    ///
    private func setup(cell: UITableViewCell, for row: Row) {
        switch row {
        case .writeNote:
            setupWriteNoteCell(cell)
        case .emailCustomer:
            setupEmailCustomerCell(cell)
        }
    }

    private func setupWriteNoteCell(_ cell: UITableViewCell) {
        guard let cell = cell as? TextViewTableViewCell else {
            fatalError()
        }

        cell.iconImage = Gridicon.iconOfType(.aside)
        cell.iconTint = isCustomerNote ? StyleManager.statusPrimaryBoldColor : StyleManager.wooGreyMid
        cell.iconImage?.accessibilityLabel = isCustomerNote ? NSLocalizedString("Note to customer", comment: "Spoken accessibility label for an icon image that indicates it's a note to the customer.") :  NSLocalizedString("Private note", comment: "Spoken accessibility label for an icon image that indicates it's a private note and is not seen by the customer.")

        cell.onTextChange = { [weak self] (text) in
            self?.navigationItem.rightBarButtonItem?.isEnabled = !text.isEmpty
            self?.noteText = text
        }
    }

    private func setupEmailCustomerCell(_ cell: UITableViewCell) {
        guard let cell = cell as? SwitchTableViewCell else {
            fatalError()
        }

        cell.topText = NSLocalizedString("Email note to customer", comment: "Label for yes/no switch - emailing the note to customer.")
        cell.bottomText = NSLocalizedString("If disabled will add the note as private.", comment: "Detail label for yes/no switch.")
        cell.accessibilityTraits = UIAccessibilityTraitButton
        cell.accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("Email note to customer %@", comment: ""), isCustomerNote ? NSLocalizedString("On", comment: "Spoken label to indicate switch control is turned on") : NSLocalizedString("Off", comment: "Spoken label to indicate switch control is turned off."))
        cell.accessibilityHint = NSLocalizedString("Double tap to toggle setting.", comment: "VoiceOver accessibility hint, informing the user that double-tapping will toggle the switch off and on.")

        cell.onToggleSwitchTouchUp = { [weak self] in
            guard let `self` = self else {
                return
            }

            self.toggleNoteType()
            self.refreshTextViewCell()
            cell.accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("Email note to customer %@", comment: ""), self.isCustomerNote ? NSLocalizedString("On", comment: "Spoken label to indicate switch control is turned on") : NSLocalizedString("Off", comment: "Spoken label to indicate switch control is turned off."))
            cell.accessibilityHint = NSLocalizedString("Double tap to toggle setting.", comment: "VoiceOver accessibility hint, informing the user that double-tapping will toggle the switch off and on.")
        }
    }

    private func refreshTextViewCell() {
        guard let cell = tableView.firstSubview(ofType: TextViewTableViewCell.self) else {
            return
        }

        setupWriteNoteCell(cell)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension AddANoteViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        setup(cell: cell, for: row)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section footers.
        return CGFloat.leastNonzeroMagnitude
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension AddANoteViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)
    }
}

// MARK: - Constants
//
private extension AddANoteViewController {
    struct Constants {
        static let rowHeight = CGFloat(44)
    }

    private struct Section {
        let title: String?
        let rows: [Row]
    }

    private enum Row {
        case writeNote
        case emailCustomer

        var reuseIdentifier: String {
            switch self {
            case .writeNote:
                return TextViewTableViewCell.reuseIdentifier
            case .emailCustomer:
                return SwitchTableViewCell.reuseIdentifier
            }
        }
    }
}
