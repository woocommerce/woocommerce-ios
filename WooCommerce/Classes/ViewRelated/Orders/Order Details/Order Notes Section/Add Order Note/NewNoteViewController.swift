import UIKit
import Yosemite
import Gridicons

class NewNoteViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet weak var tableView: UITableView!

    var viewModel: NewNoteViewModel

    init(viewModel: NewNoteViewModel) {
        self.viewModel = viewModel
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var sections = [Section]()

    private var isCustomerNote = false

    private var noteText: String = ""

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

        viewModel.trackOrderNoteAddButtonTapped()
        viewModel.trackOrderNoteAdd(isCustomerNote)

        let action = OrderNoteAction.addOrderNote(siteID: viewModel.order.siteID,
                                                  orderID: viewModel.orderID,
                                                  isCustomerNote: isCustomerNote,
                                                  note: noteText) { [weak self] (orderNote, error) in
            if let error = error {
                DDLogError("⛔️ Error adding a note: \(error.localizedDescription)")
                self?.viewModel.track(.orderNoteAddFailed, withError: error)

                self?.displayErrorNotice()
                self?.configureForEditingNote()
                return
            }

            if let orderNote = orderNote {
                self?.viewModel.onDidFinishEditing?(orderNote)
            }

            self?.viewModel.track(.orderNoteAddSuccess)
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
        tableView.registerNib(for: TextViewTableViewCell.self)
        tableView.registerNib(for: SwitchTableViewCell.self)
    }

    /// Setup: Sections
    ///
    private func loadSections() {
        let writeNoteSectionTitle = NSLocalizedString("WRITE NOTE", comment: "Add a note screen - Write Note section title")
        let writeNoteSection = Section(title: writeNoteSectionTitle, rows: [.writeNote])
        let emailCustomerSection: Section? = {
            if viewModel.order.billingAddress?.hasEmailAddress == true {
                return Section(title: nil, rows: [.emailCustomer])
            }
            return nil
        }()

        sections = [writeNoteSection, emailCustomerSection].compactMap { $0 }
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

        let iconAccessibilityLabel = isCustomerNote ?
        NSLocalizedString("Note to customer",
                          comment: "Spoken accessibility label for an icon image that indicates it's a note to the customer.") :
        NSLocalizedString("Private note",
                          comment: "Spoken accessibility label for an icon image that indicates it's a private note and is not seen by the customer.")
        let cellViewModel = TextViewTableViewCell.ViewModel(icon: .asideImage,
                                                            iconAccessibilityLabel: iconAccessibilityLabel,
                                                            iconTint: isCustomerNote ? .primary : .textSubtle,
                                                            onTextChange: { [weak self] (text) in
                                                                self?.navigationItem.rightBarButtonItem?.isEnabled = !text.isEmpty
                                                                self?.noteText = text
        })

        cell.configure(with: cellViewModel)
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
            self.viewModel.trackOrderNoteEmailCustomerToggled(stateValue)
        }
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
        let titleFormat = NSLocalizedString(
            "Unable to add note to order #%1$d",
            comment: "Content of error presented when Add Note Action Failed. "
                + "It reads: Unable to add note to order #{order number}. "
                + "Parameters: %1$d - order number"
        )
        let title = String.localizedStringWithFormat(titleFormat, viewModel.orderID)

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
        let titleFormat = NSLocalizedString("Order #%1$@", comment: "Add a note screen - title. Example: Order #15. Parameters: %1$@ - order number")
        title = String.localizedStringWithFormat(titleFormat, viewModel.orderNumber)
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
        let activityIndicator = UIActivityIndicatorView(style: .medium)
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
