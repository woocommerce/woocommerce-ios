import Foundation
import UIKit
import WordPressAuthenticator
import WordPressUI
import Storage
import Yosemite



/// Allows the user to pick which WordPress.com (OR) Jetpack-Connected-Store we should set up as the Main Store.
///
class StorePickerViewController: UIViewController {

    /// Represents the internal StorePicker State
    ///
    private var state: StorePickerState = .empty {
        didSet {
            stateWasUpdated()
        }
    }

    /// Header View: Displays all of the Account Details
    ///
    private let accountHeaderView: AccountHeaderView = {
        return AccountHeaderView.instantiateFromNib()
    }()

    /// ResultsController: Loads Sites from the Storage Layer.
    ///
    private let resultsController: ResultsController<Storage.Site> = {
        let viewContext = CoreDataManager.global.viewContext
        let predicate = NSPredicate(format: "isWordPressStore == YES")
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController(viewContext: viewContext, matching: predicate, sortedBy: [descriptor])
    }()

    /// White-Background View, to be placed surrounding the bottom area.
    ///
    @IBOutlet private var actionBackgroundView: UIView! {
        didSet {
            actionBackgroundView.layer.masksToBounds = false
            actionBackgroundView.layer.shadowOpacity = StorePickerConstants.backgroundShadowOpacity
        }
    }

    /// Default Action Button.
    ///
    @IBOutlet private var actionButton: UIButton! {
        didSet {
            actionButton.backgroundColor = .clear
        }
    }

    /// No Results Placeholder Image
    ///
    @IBOutlet private var noResultsImageView: UIImageView!

    /// No Results Placeholder Text
    ///
    @IBOutlet private var noResultsLabel: UILabel! {
        didSet {
            noResultsLabel.font = StyleManager.subheadlineFont
            noResultsLabel.textColor = StyleManager.wooGreyTextMin
        }
    }

    /// Main tableView
    ///
    @IBOutlet private var tableView: UITableView! {
        didSet {
            tableView.tableHeaderView = accountHeaderView
        }
    }

    /// Closure to be executed upon dismissal.
    ///
    var onDismiss: (() -> Void)?



    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMainView()
        setupAccountHeader()
        setupTableView()
        refreshResults()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDismiss?()
    }
}


// MARK: - Initialization Methods
//
private extension StorePickerViewController {

    func setupMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func setupTableView() {
        let cells = [
            EmptyStoresTableViewCell.reuseIdentifier: EmptyStoresTableViewCell.loadNib(),
            StoreTableViewCell.reuseIdentifier: StoreTableViewCell.loadNib()
        ]

        for (reuseIdentifier, nib) in cells {
            tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
        }
    }

    func setupAccountHeader() {
        guard let defaultAccount = StoresManager.shared.sessionManager.defaultAccount else {
            return
        }

        accountHeaderView.username = "@" + defaultAccount.username
        accountHeaderView.fullname = defaultAccount.displayName
        accountHeaderView.downloadGravatar(with: defaultAccount.email)
    }

    func refreshResults() {
        try? resultsController.performFetch()
        state = StorePickerState(sites: resultsController.fetchedObjects)
    }

    func stateWasUpdated() {
        tableView.separatorStyle = state.separatorStyle
        actionButton.setTitle(state.actionTitle, for: .normal)
        tableView.reloadData()
    }
}


// MARK: - Action Handlers
//
extension StorePickerViewController {

    /// Proceeds with the Login Flow.
    ///
    @IBAction func actionWasPressed() {
        dismiss(animated: true, completion: nil)
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension StorePickerViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return state.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return state.numberOfRows
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return state.headerTitle?.uppercased()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let site = state.site(at: indexPath) else {
            return tableView.dequeueReusableCell(withIdentifier: EmptyStoresTableViewCell.reuseIdentifier, for: indexPath)
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: StoreTableViewCell.reuseIdentifier, for: indexPath) as? StoreTableViewCell else {
            fatalError()
        }

        cell.name = site.name
        cell.url = site.url

        return cell
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension StorePickerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


// MARK: - StorePickerConstants: Contains all of the constants required by the Picker.
//
private enum StorePickerConstants {
    static let backgroundShadowOpacity = Float(0.2)
    static let numberOfSections = 1
    static let emptyStateRowCount = 1
}


// MARK: - Represents the StorePickerViewController's Internal State.
//
private enum StorePickerState {

    /// No Stores onScreen
    ///
    case empty

    /// Stores Available!
    ///
    case available(sites: [Yosemite.Site])


    /// Designated Initializer
    ///
    init(sites: [Yosemite.Site]) {
        if sites.isEmpty {
            self = .empty
        } else {
            self = .available(sites: sites)
        }
    }
}


// MARK: - StorePickerState Properties
//
private extension StorePickerState {

    /// Action Button's Title
    ///
    var actionTitle: String {
        switch self {
        case .empty:
            return NSLocalizedString("Try another account", comment: "")
        default:
            return NSLocalizedString("Continue", comment: "")
        }
    }

    /// Results Table's Header Title
    ///
    var headerTitle: String? {
        switch self {
        case .empty:
            return nil
        case .available(let sites) where sites.count > 1:
            return NSLocalizedString("Pick Store to Connect", comment: "Store Picker's Section Title: Displayed whenever there are multiple Stores.")
        default:
            return NSLocalizedString("Connected Store", comment: "Store Picker's Section Title: Displayed when there's a single pre-selected Store.")
        }
    }

    /// Number of TableView Sections
    ///
    var numberOfSections: Int {
        return StorePickerConstants.numberOfSections
    }

    /// Number of TableView Rows
    ///
    var numberOfRows: Int {
        switch self {
        case .available(let sites):
            return sites.count
        default:
            return StorePickerConstants.emptyStateRowCount
        }
    }

    /// Results Table's Separator Style
    ///
    var separatorStyle: UITableViewCellSeparatorStyle {
        switch self {
        case .empty:
            return .none
        default:
            return .singleLine
        }
    }

    /// Returns the site to be displayed at a given IndexPath
    ///
    func site(at indexPath: IndexPath) -> Yosemite.Site? {
        switch self {
        case .empty:
            return nil
        case .available(let sites):
            return sites[indexPath.row]
        }
    }
}
