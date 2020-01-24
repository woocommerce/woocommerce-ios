import UIKit
import Yosemite
import Gridicons

class NewNoteViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet var tableView: UITableView!

    var viewModel: OrderDetailsViewModel!

    private var sections = [Section]()

    private var isCustomerNote = false

    private var noteText: String = ""

    private var emailCustomerSwitch: Bool = false

    /// Dedicated NoticePresenter (use this here instead of ServiceLocator.noticePresenter)
    ///
    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

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
        showKeyboard()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func addButtonTapped() {
        configureForCommittingNote()

        ServiceLocator.analytics.track(.orderNoteAddButtonTapped)
        ServiceLocator.analytics.track(.orderNoteAdd, withProperties: ["parent_id": viewModel.order.orderID,
                                                                  "status": viewModel.order.statusKey,
                                                                  "type": isCustomerNote ? "customer" : "private"])

        let action = OrderNoteAction.addOrderNote(siteID: viewModel.order.siteID,
                                                  orderID: viewModel.order.orderID,
                                                  isCustomerNote: isCustomerNote,
                                                  note: noteText) { [weak self] (orderNote, error) in
            if let error = error {
                DDLogError("⛔️ Error adding a note: \(error.localizedDescription)")
                ServiceLocator.analytics.track(.orderNoteAddFailed, withError: error)

                self?.displayErrorNotice()
                self?.configureForEditingNote()
                return
            }

                                                    if let orderNote = orderNote {
                                                                  self?.viewModel.orderNotes.insert(orderNote, at: 0)
                                                              }

            ServiceLocator.analytics.track(.orderNoteAddSuccess)
            self?.dismiss(animated: true, completion: nil)
        }

        ServiceLocator.stores.dispatch(action)
    }
}

// MARK: - TableView Configuration
//
private extension NewNoteViewController {
    /// Setup: TableView
    ///
    private func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
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

        cell.iconImage = .asideImage
        cell.iconTint = isCustomerNote ? .listIcon : .textSubtle
        cell.iconTint = emailCustomerSwitch == true ? .primary : .listIcon
        cell.iconImage?.accessibilityLabel = isCustomerNote ?
            NSLocalizedString("Note to customer",
                              comment: "Spoken accessibility label for an icon image that indicates it's a note to the customer.") :
            NSLocalizedString("Private note",
                              comment: "Spoken accessibility label for an icon image that indicates it's a private note and is not seen by the customer.")

        cell.onTextChange = { [weak self] (text) in
            self?.navigationItem.rightBarButtonItem?.isEnabled = !text.isEmpty
            self?.noteText = text
        }
    }

    private func setupEmailCustomerCell(_ cell: UITableViewCell) {
        guard let cell = cell as? SwitchTableViewCell else {
            fatalError()
        }

        cell.title = NSLocalizedString("Email note to customer", comment: "Label for yes/no switch - emailing the note to customer.")
        cell.subtitle = NSLocalizedString("If disabled the note will be private", comment: "Detail label for yes/no switch.")
        cell.accessibilityTraits = .button
        cell.accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString("Email note to customer %@", comment: ""),
            isCustomerNote ?
                NSLocalizedString("On", comment: "Spoken label to indicate switch control is turned on") :
                NSLocalizedString("Off", comment: "Spoken label to indicate switch control is turned off.")
        )
        cell.accessibilityHint = NSLocalizedString(
            "Double tap to toggle setting.",
            comment: "VoiceOver accessibility hint, informing the user that double-tapping will toggle the switch off and on."
        )

        cell.onChange = { [weak self] newValue in
            guard let `self` = self else {
                return
            }

            self.isCustomerNote = newValue

            cell.accessibilityLabel = String.localizedStringWithFormat(
                NSLocalizedString("Email note to customer %@", comment: ""),
                newValue ?
                    NSLocalizedString("On", comment: "Spoken label to indicate switch control is turned on") :
                    NSLocalizedString("Off", comment: "Spoken label to indicate switch control is turned off.")
            )

            let stateValue = newValue ? "on" : "off"
            ServiceLocator.analytics.track(.orderNoteEmailCustomerToggled, withProperties: ["state": stateValue])

            self.emailCustomerSwitch = stateValue == "on" ? true : false
            self.refreshTextViewCell()
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
extension NewNoteViewController: UITableViewDataSource {
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
extension NewNoteViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)
    }
}

// MARK: - Error Notice
//
private extension NewNoteViewController {
    func displayErrorNotice() {
        let title = NSLocalizedString(
            "Unable to add note to order #\(viewModel.order.orderID)",
            comment: "Content of error presented when Add Note Action Failed. It reads: Unable to add note to order #{order number}"
        )

        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: title, message: nil, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.addButtonTapped()
        }

        noticePresenter.enqueue(notice: notice)
    }
}

// MARK: - Navigation bar
//
private extension NewNoteViewController {
    func configureNavigation() {
        configureTitle()
        configureDismissButton()
        configureRightButtonItemAsAdd()
    }

    func configureTitle() {
        title = NSLocalizedString("Order #\(viewModel.order.number)",
            comment: "Add a note screen - title. Example: Order #15")
    }

    func configureDismissButton() {
        let dismissButtonTitle = NSLocalizedString("Dismiss",
                                                   comment: "Add a note screen - button title for closing the view")
        let leftBarButton = UIBarButtonItem(title: dismissButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(dismissButtonTapped))
        navigationItem.setLeftBarButton(leftBarButton, animated: false)
    }

    func configureRightButtonItemAsAdd() {
        let addButtonTitle = NSLocalizedString("Add",
                                               comment: "Add a note screen - button title to send the note")
        let rightBarButton = UIBarButtonItem(title: addButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(addButtonTapped))
        navigationItem.setRightBarButton(rightBarButton, animated: false)
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    func configureForCommittingNote() {
        hideKeyboard()
        configureRightButtonItemAsSpinner()
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    func configureRightButtonItemAsSpinner() {
        let activityIndicator = UIActivityIndicatorView(style: .white)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()

        let rightBarButton = UIBarButtonItem(customView: activityIndicator)

        navigationItem.setRightBarButton(rightBarButton, animated: true)
    }

    func configureForEditingNote() {
        configureRightButtonItemAsAdd()
        navigationItem.rightBarButtonItem?.isEnabled = true
    }

    func showKeyboard() {
        tableView.firstSubview(ofType: UITextView.self)?.becomeFirstResponder()
    }

    func hideKeyboard() {
        tableView.firstSubview(ofType: UITextView.self)?.resignFirstResponder()
    }
}

// MARK: - Constants
//
private extension NewNoteViewController {
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
