import UIKit
import Yosemite

class AddANoteViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet var tableView: UITableView!

    var order: Order!

    private var sections = [Section]()

    private var isCustomerNote = false

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTableView()
        registerTableViewCells()
        loadSections()
    }

    func configureNavigation() {
        title = NSLocalizedString("Order #\(order.number)", comment: "Add a note screen - title. Example: Order #15")

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
    }

    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func addButtonTapped() {
        NSLog("Add button tapped!")
    }
}

// MARK: - TableView Configuration
//
private extension AddANoteViewController {
    /// Setup: TableView
    ///
    private func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    /// Registers all of the available TableViewCells
    ///
    private func registerTableViewCells() {
        let cells = [
            WriteCustomerNoteTableViewCell.self,
            ToggleEmailCustomerTableViewCell.self
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
        guard let cell = cell as? WriteCustomerNoteTableViewCell else {
            fatalError()
        }

        cell.isCustomerNote = isCustomerNote
    }

    private func setupEmailCustomerCell(_ cell: UITableViewCell) {
        guard let cell = cell as? ToggleEmailCustomerTableViewCell else {
            fatalError()
        }

        cell.onToggleSwitchTouchUp = { [weak self] in
            self?.toggleNoteType()
            self?.tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension AddANoteViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
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
                return WriteCustomerNoteTableViewCell.reuseIdentifier
            case .emailCustomer:
                return ToggleEmailCustomerTableViewCell.reuseIdentifier
            }
        }
    }
}
