import Combine
import Foundation
import UIKit
import Yosemite
import WordPressUI

import class AutomatticTracks.CrashLogging


/// SearchViewController: Displays the Search Interface for A Generic Model
///
final class SearchViewController<Cell: UITableViewCell & SearchResultCell, Command: SearchUICommand>:
    UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate
where Cell.SearchModel == Command.CellViewModel {

    /// Dismiss Action
    ///
    @IBOutlet private var cancelButton: UIButton!

    /// Main SearchBar
    ///
    @IBOutlet private var searchBar: UISearchBar!

    /// Optional header view between the search bar and table view.
    @IBOutlet private weak var headerView: UIView!

    /// TableView
    ///
    @IBOutlet private var tableView: UITableView!


    @IBOutlet private weak var bordersView: BordersView!

    /// Current query in the search bar
    ///
    @Published private var searchQuery = ""

    /// A reference to the subscription of the search query.
    ///
    private var searchQuerySubscription: AnyCancellable?

    /// Footer "Loading More" Spinner.
    ///
    private lazy var footerSpinnerView = FooterSpinnerView()

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) models in sync.
    ///
    private let resultsController: ResultsController<Command.ResultsControllerModel>

    /// Predicate for the results controller from the command.
    ///
    private let resultsPredicate: NSPredicate?

    /// The controller of the view to show if there is no search `keyword` entered.
    ///
    /// If `nil`, the `tableView` will be shown instead.
    ///
    /// - SeeAlso: State.starter
    ///
    private var starterViewController: UIViewController?

    /// The controller of the view to show if the search results are empty.
    ///
    /// - SeeAlso: State.empty
    ///
    private lazy var emptyStateViewController: Command.EmptyStateViewControllerType = searchUICommand.createEmptyStateViewController()

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// Search Store ID
    ///
    private let storeID: Int64

    /// Indicates if there are no results onscreen.
    ///
    private var isEmpty: Bool {
        return resultsController.isEmpty
    }

    /// UI Active State
    ///
    private var state: State = .notInitialized {
        didSet {
            didLeave(state: oldValue)
            didEnter(state: state)
        }
    }

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        let keyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
            self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
        }
        return keyboardFrameObserver
    }()

    private var searchUICommand: Command
    private let tableViewSeparatorStyle: UITableViewCell.SeparatorStyle


    /// Designated Initializer
    ///
    init(storeID: Int64,
         command: Command,
         cellType: Cell.Type,
         cellSeparator: UITableViewCell.SeparatorStyle) {
        self.resultsController = command.createResultsController()
        self.resultsPredicate = resultsController.predicate
        self.searchUICommand = command
        self.storeID = storeID
        tableViewSeparatorStyle = cellSeparator
        super.init(nibName: "SearchViewController", bundle: nil)
    }

    /// Unsupported: NSCoder
    ///
    required init?(coder aDecoder: NSCoder) {
        assertionFailure()
        return nil
    }


    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        registerTableViewCells()

        configureSyncingCoordinator()
        configureCancelButton()
        configureActions()
        configureMainView()
        configureSearchBar()
        configureSearchBarBordersView()
        configureHeaderView()
        configureTableView()
        configureResultsController()
        configureStarterViewController()
        configureSearchResync()

        startListeningToNotifications()

        transitionToResultsUpdatedState()
        configureSearchFunctionality()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)
        searchBar.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Note: configuring the search bar text color does not work in `viewDidLoad` and `viewWillAppear`.
        configureSearchBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - UITableViewDataSource Conformance
    //

    func numberOfSections(in tableView: UITableView) -> Int {
        return resultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(Cell.self, for: indexPath)

        let model = resultsController.object(at: indexPath)
        let cellModel = searchUICommand.createCellViewModel(model: model)
        cell.configureCell(searchModel: cellModel)
        return cell
    }

    // MARK: - UITableViewDelegate Conformance
    //

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let model = resultsController.safeObject(at: indexPath) else {
            return
        }
        searchUICommand.didSelectSearchResult(model: model, from: self, reloadData: { [weak self] in
            self?.tableView.reloadData()
        }, updateActionButton: { [weak self] in
            guard let self = self else {
                return
            }
            self.searchUICommand.configureActionButton(self.cancelButton, onDismiss: { [weak self] in
                self?.dismissWasPressed()
            })
        })
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let objectIndex = resultsController.objectIndex(from: indexPath)
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: objectIndex)
    }

    // MARK: - UISearchBarDelegate Conformance
    //
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchQuery = searchText
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }

    // MARK: - Actions
    //

    @IBAction func dismissWasPressed() {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        applyAdditionalKeyboardFrameHeightTo(children)
    }
}

// MARK: - Keyboard Handling

extension SearchViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
    }
}

private extension SearchViewController {
    func applyAdditionalKeyboardFrameHeightTo(_ viewControllers: [UIViewController]) {
        viewControllers.compactMap {
            $0 as? KeyboardFrameAdjustmentProvider
        }.forEach {
            $0.additionalKeyboardFrameHeight = 0 - view.safeAreaInsets.bottom
        }
    }
}

// MARK: - User Interface Initialization
//
private extension SearchViewController {

    /// Setup: Main View
    ///
    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        tableView.backgroundColor = .listBackground
        tableView.estimatedRowHeight = Settings.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = footerSpinnerView
        tableView.separatorStyle = tableViewSeparatorStyle
    }

    /// Setup: Search Bar
    ///
    func configureSearchBar() {
        searchBar.placeholder = searchUICommand.searchBarPlaceholder
        searchBar.accessibilityIdentifier = searchUICommand.searchBarAccessibilityIdentifier
        searchBar.searchTextField.textColor = .text
    }

    /// Setup: Search Bar Borders
    ///
    func configureSearchBarBordersView() {
        bordersView.bottomColor = .systemColor(.separator)
    }

    /// Setup: Cancel Button
    ///
    func configureCancelButton() {
        cancelButton.applyModalCancelButtonStyle()
        cancelButton.accessibilityIdentifier = searchUICommand.cancelButtonAccessibilityIdentifier
    }

    func configureHeaderView() {
        if let searchHeaderView = searchUICommand.createHeaderView() {
            headerView.addSubview(searchHeaderView)
            searchHeaderView.translatesAutoresizingMaskIntoConstraints = false
            headerView.pinSubviewToSafeArea(searchHeaderView)
        } else {
            headerView.isHidden = true
            NSLayoutConstraint.activate([
                headerView.heightAnchor.constraint(equalToConstant: 0)
            ])
        }
    }

    /// Setup: Actions
    ///
    func configureActions() {
        let title = NSLocalizedString("Cancel", comment: "")
        cancelButton.setTitle(title, for: .normal)
    }

    /// Setup: Results Controller
    ///
    func configureResultsController() {
        resultsController.startForwardingEvents(to: tableView)

        do {
            try resultsController.performFetch()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }

        tableView.reloadData()
        tableView.accessibilityIdentifier = "default-search-results-table-view"
    }

    /// Create and add `starterViewController` to the `view.`
    ///
    func configureStarterViewController() {
        guard let starterViewController = searchUICommand.createStarterViewController(),
            let starterView = starterViewController.view else {
                return
        }

        starterView.translatesAutoresizingMaskIntoConstraints = false

        add(starterViewController)
        view.addSubview(starterView)

        // Match the position and size to the `tableView`.
        NSLayoutConstraint.activate([
            starterView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            starterView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            starterView.topAnchor.constraint(equalTo: tableView.topAnchor),
            starterView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ])

        starterViewController.didMove(toParent: self)

        starterView.isHidden = true

        self.starterViewController = starterViewController
    }

    /// Setup: Sync'ing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        Cell.register(for: tableView)
    }

    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }

    /// Handles debouncing search upon update of search query to optimize search requests.
    ///
    func configureSearchFunctionality() {
        searchQuerySubscription = $searchQuery
            .dropFirst() // ignores initial value as it's not user's input
            .removeDuplicates()
            .debounce(for: .milliseconds(Settings.searchDebounceTime), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.synchronizeSearchResults(with: query)
            }
    }

    func configureSearchResync() {
        searchUICommand.resynchronizeModels = { [weak self] in
            guard let self = self else { return }
            self.synchronizeSearchResults(with: self.searchQuery)
        }
    }
}


// MARK: - SyncingCoordinatorDelegate Conformance
//
extension SearchViewController: SyncingCoordinatorDelegate {

    /// Synchronizes the models for the Default Store (if any).
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: ((Bool) -> Void)? = nil) {
        transitionToSyncingState()
        let keyword = searchUICommand.sanitizeKeyword(searchQuery)
        searchUICommand.synchronizeModels(siteID: storeID,
                                          keyword: keyword,
                                          pageNumber: pageNumber,
                                          pageSize: pageSize,
                                          onCompletion: { [weak self] isCompleted in
            guard let self = self else { return }
            // Disregard OPs that don't really match the latest keyword
            if keyword == self.searchUICommand.sanitizeKeyword(self.searchQuery) {
                self.transitionToResultsUpdatedState()
            }
            onCompletion?(isCompleted)
        })
    }
}


// MARK: - Actions
//
private extension SearchViewController {

    /// Updates the Predicate + Triggers a Sync Event
    ///
    func synchronizeSearchResults(with keyword: String) {
        // When the search query changes, also includes the original results predicate in addition to the search keyword.
        let keyword = searchUICommand.sanitizeKeyword(keyword)
        let searchResultsPredicate = searchUICommand.searchResultsPredicate(keyword: keyword)
        let subpredicates = [resultsPredicate].compactMap { $0 } + [searchResultsPredicate].compactMap { $0 }
        resultsController.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        do {
            try resultsController.performFetch()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }

        tableView.setContentOffset(.zero, animated: false)
        tableView.reloadData()
        tableView.accessibilityIdentifier = "updated-search-results-table-view"

        syncingCoordinator.resynchronize()
    }
}


// MARK: - Spinner Helpers
//
extension SearchViewController {

    /// Starts the Footer Spinner animation, whenever `mustStartFooterSpinner` returns *true*.
    ///
    private func ensureFooterSpinnerIsStarted() {
        guard mustStartFooterSpinner() else {
            return
        }

        footerSpinnerView.startAnimating()
    }

    /// Whenever we're sync'ing a page of models that's beyond what we're currently displaying, this method will return *true*.
    ///
    private func mustStartFooterSpinner() -> Bool {
        guard let highestPageBeingSynced = syncingCoordinator.highestPageBeingSynced else {
            return false
        }

        return highestPageBeingSynced * SyncingCoordinator.Defaults.pageSize > resultsController.numberOfObjects
    }

    /// Stops animating the Footer Spinner.
    ///
    private func ensureFooterSpinnerIsStopped() {
        footerSpinnerView.stopAnimating()
    }
}


// MARK: - Placeholders
//
private extension SearchViewController {

    /// Displays the view for the empty state.
    ///
    func displayEmptyState() {
        // Create the controller if it doesn't exist yet
        let childController = emptyStateViewController

        // Abort if we are already displaying this childController
        guard childController.parent == nil else {
            return
        }

        // Before creating the view (below), give the childController the keyboard adjustments
        // they should use. This simplifies any keyboard observation they have in  `viewDidLoad`.
        applyAdditionalKeyboardFrameHeightTo([childController])

        // Create the view by accessing `.view`. This should trigger `viewDidLoad`.
        guard let childView = childController.view else {
            return
        }

        searchUICommand.configureEmptyStateViewControllerBeforeDisplay(viewController: childController,
                                                                       searchKeyword: searchQuery)

        childView.translatesAutoresizingMaskIntoConstraints = false

        add(childController)
        view.addSubview(childView)

        // Match the position and size to the `tableView`. Attach top to the searchBar
        NSLayoutConstraint.activate([
            childView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            childView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        childController.didMove(toParent: self)
    }

    /// Removes the view for the empty state.
    ///
    func removeEmptyState() {
        let childController = emptyStateViewController

        guard let childView = childController.view,
              childController.parent == self else {
            return
        }

        childController.willMove(toParent: nil)
        childView.removeFromSuperview()
        childController.removeFromParent()
    }
}


// MARK: - FSM
//
private extension SearchViewController {

    func didEnter(state: State) {
        switch state {
        case .starter:
            tableView.isHidden = true
            starterViewController?.view.isHidden = false
        case .empty:
            displayEmptyState()
        case .syncing:
            ensureFooterSpinnerIsStarted()
        case .results, .notInitialized:
            break
        }
    }

    func didLeave(state: State) {
        switch state {
        case .starter:
            starterViewController?.view.isHidden = true
            tableView.isHidden = false
        case .empty:
            removeEmptyState()
        case .syncing:
            ensureFooterSpinnerIsStopped()
        case .results, .notInitialized:
            break
        }
    }

    /// The state to use if the `keyword` is empty.
    ///
    var stateIfSearchKeywordIsEmpty: State {
        starterViewController != nil ? .starter : .results
    }

    /// Transition to the appropriate `State` after a search request was executed.
    ///
    /// See `State` for the rules.
    ///
    func transitionToSyncingState() {
        state = searchQuery.isEmpty ? stateIfSearchKeywordIsEmpty : .syncing
    }

    /// Transition to the appropriate `State` after search results were received.
    ///
    /// See `State` for the rules.
    ///
    func transitionToResultsUpdatedState() {
        let nextState: State

        if searchQuery.isEmpty {
            nextState = stateIfSearchKeywordIsEmpty
        } else if isEmpty {
            nextState = .empty
        } else {
            nextState = .results
        }

        state = nextState
    }
}


// MARK: - Private Settings
//
private enum Settings {
    static let estimatedHeaderHeight = CGFloat(43)
    static let estimatedRowHeight = CGFloat(86)
    static let searchDebounceTime = 500
}


// MARK: - FSM States
//
private enum State {
    /// The view has not been loaded yet.
    ///
    case notInitialized
    /// The state when there is no search `keyword` and the `starterViewController` is shown.
    ///
    /// This state is never reached if `starterViewController` is `nil`.
    ///
    case starter
    /// The state when there are search results.
    ///
    /// This is also the default `state` if there is no `starterViewController`. Search result
    /// providers (i.e. `SearchUICommand`) can opt to show a default list of items in this case.
    ///
    case results
    /// The state when a `keyword` is entered and a search is in progress.
    ///
    case syncing
    /// The state when the search has finished but there are no results.
    ///
    case empty
}
