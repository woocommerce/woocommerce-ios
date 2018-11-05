import UIKit
import Gridicons
import Yosemite


// MARK: - NotificationsViewController
//
class NotificationsViewController: UIViewController {

    /// Main TableView.
    ///
    @IBOutlet private var tableView: UITableView!

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Notes in sync.
    ///
    private lazy var resultsController: ResultsController<StorageNote> = {
        let storageManager = AppDelegate.shared.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageNote.timestamp, ascending: false)

        return ResultsController<StorageNote>(storageManager: storageManager, sectionNameKeyPath: "normalizedAgeAsString", sortedBy: [descriptor])
    }()

    /// Rendered Subjects Cache.
    ///
    private var subjectStorage = [Int64: NSAttributedString]()

    /// Rendered Snippet Cache.
    ///
    private var snippetStorage = [Int64: NSAttributedString]()

    /// String Formatter: Given a NoteBlock, this tool will return an AttributedString.
    ///
    private let formatter = StringFormatter()



    // MARK: - View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureTabBarItem()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = StyleManager.tableViewBackgroundColor

        configureTableView()
        configureTableViewCells()
        configureResultsController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        synchronizeNotifications()
    }
}


// MARK: - User Interface Initialization
//
private extension NotificationsViewController {

    /// Setup: TabBar
    ///
    func configureTabBarItem() {
        tabBarItem.title = NSLocalizedString("Notifications", comment: "Notifications tab title")
        tabBarItem.image = Gridicon.iconOfType(.statsAlt)
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.rowHeight = UITableView.automaticDimension
    }

    /// Setup: ResultsController
    ///
    func configureResultsController() {
        resultsController.startForwardingEvents(to: tableView)
        try? resultsController.performFetch()
    }

    /// Setup: TableViewCells
    ///
    func configureTableViewCells() {
        let cells = [NoteTableViewCell.self]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }
}


// MARK: - Sync'ing Helpers
//
private extension NotificationsViewController {

    /// Synchronizes the Notifications associated to the active WordPress.com account.
    ///
    func synchronizeNotifications() {
        let action = NotificationAction.synchronizeNotifications { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing notifications: \(error)")
            }
        }

        StoresManager.shared.dispatch(action)
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension NotificationsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return resultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NoteTableViewCell.reuseIdentifier) as? NoteTableViewCell else {
            fatalError()
        }

        configure(cell, at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let rawAge = resultsController.sections[section].name
        return Age(rawValue: rawAge)?.description
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension NotificationsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


// MARK: - Cell Setup
//
private extension NotificationsViewController {

    /// Initializes the Notifications Cell at the specified indexPath
    ///
    func configure(_ cell: NoteTableViewCell, at indexPath: IndexPath) {
        let note = resultsController.object(at: indexPath)

        cell.noticon = note.noticon
        cell.attributedSubject = renderSubject(note: note)
        cell.attributedSnippet = renderSnippet(note: note)
    }
}


// MARK: - Formatting
//
private extension NotificationsViewController {

    /// Returns the formatted Subject (if any). For performance reasons, we'll cache the result.
    ///
    func renderSubject(note: Note) -> NSAttributedString? {
        if let cached = subjectStorage[note.hash] {
            return cached
        }

        let subject = note.blockForSubject.map { formatter.format(block: $0, with: .subject) }
        subjectStorage[note.hash] = subject

        return subject
    }

    /// Returns the formatted Snippet (if any). For performance reasons, we'll cache the result.
    ///
    func renderSnippet(note: Note) -> NSAttributedString? {
        if let cached = snippetStorage[note.hash] {
            return cached
        }

        let snippet = note.blockForSnippet.map { formatter.format(block: $0, with: .snippet) }
        snippetStorage[note.hash] = snippet

        return snippet
    }
}
