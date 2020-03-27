import Foundation
import UIKit
import Yosemite
import WordPressUI


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

    /// TableView
    ///
    @IBOutlet private var tableView: UITableView!


    @IBOutlet private weak var bordersView: BordersView!

    /// Footer "Loading More" Spinner.
    ///
    private lazy var footerSpinnerView = {
        return FooterSpinnerView(tableViewStyle: tableView.style)
    }()

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) models in sync.
    ///
    private let resultsController: ResultsController<Command.ResultsControllerModel>

    /// The controller of the view to show if there is no search `keyword` entered.
    ///
    /// If `nil`, the `tableView` will be shown instead.
    ///
    /// - SeeAlso: State.starter
    ///
    private var starterViewController: UIViewController?

    /// The controller of the view to show if the search results are empty.
    ///
    /// This is created once and only on demand.
    ///
    /// - SeeAlso: State.empty
    ///
    private var emptyStateViewController: Command.EmptyStateViewControllerType?

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

    /// Returns the active Keyword
    ///
    private var keyword: String {
        return searchBar.text ?? String()
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
        let keyboardFrameObserver = KeyboardFrameObserver(onKeyboardFrameUpdate: handleKeyboardFrameUpdate(keyboardFrame:))
        return keyboardFrameObserver
    }()

    private let searchUICommand: Command


    /// Designated Initializer
    ///
    init(storeID: Int64,
         command: Command,
         cellType: Cell.Type) {
        self.resultsController = command.createResultsController()
        self.searchUICommand = command
        self.storeID = storeID
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
        configureTableView()
        configureResultsController()
        configureStarterViewController()

        startListeningToNotifications()

        transitionToResultsUpdatedState()
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier, for: indexPath) as? Cell else {
            fatalError()
        }

        let model = resultsController.object(at: indexPath)
        let cellModel = searchUICommand.createCellViewModel(model: model)
        cell.configureCell(searchModel: cellModel)
        return cell
    }

    // MARK: - UITableViewDelegate Conformance
    //

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = resultsController.object(at: indexPath)
        searchUICommand.didSelectSearchResult(model: model, from: self)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let objectIndex = resultsController.objectIndex(from: indexPath)
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: objectIndex)
    }

    // MARK: - UISearchBarDelegate Conformance
    //
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        synchronizeSearchResults(with: searchText)
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
        children.compactMap {
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
    }

    /// Setup: Search Bar
    ///
    func configureSearchBar() {
        searchBar.placeholder = searchUICommand.searchBarPlaceholder
        searchBar.accessibilityIdentifier = searchUICommand.searchBarAccessibilityIdentifier

        if #available(iOS 13.0, *) {
            searchBar.searchTextField.textColor = .text
        }
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
        try? resultsController.performFetch()
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
}


// MARK: - SyncingCoordinatorDelegate Conformance
//
extension SearchViewController: SyncingCoordinatorDelegate {

    /// Synchronizes the models for the Default Store (if any).
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: ((Bool) -> Void)? = nil) {
        let keyword = self.keyword
        searchUICommand.synchronizeModels(siteID: storeID,
                                          keyword: keyword,
                                          pageNumber: pageNumber,
                                          pageSize: pageSize,
                                        onCompletion: { [weak self] isCompleted in
                                            // Disregard OPs that don't really match the latest keyword
                                            if keyword == self?.keyword {
                                                self?.transitionToResultsUpdatedState()
                                            }
                                            onCompletion?(isCompleted)
        })
        transitionToSyncingState()
    }
}


// MARK: - Actions
//
private extension SearchViewController {

    /// Updates the Predicate + Triggers a Sync Event
    ///
    func synchronizeSearchResults(with keyword: String) {
        resultsController.predicate = NSPredicate(format: "ANY searchResults.keyword = %@", keyword)

        tableView.setContentOffset(.zero, animated: false)
        tableView.reloadData()

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
        let childController: Command.EmptyStateViewControllerType = {
            if let existing = emptyStateViewController {
                return existing
            } else {
                let created = searchUICommand.createEmptyStateViewController()
                emptyStateViewController = created
                return created
            }
        }()
        guard let childView = childController.view,
              childController.parent == nil else {
            return
        }
        
        searchUICommand.configureEmptyStateViewControllerBeforeDisplay(childController, searchKeyword: keyword)

        childView.translatesAutoresizingMaskIntoConstraints = false

        add(childController)
        view.addSubview(childView)

        // Match the position and size to the `tableView`. Attach top to the searchBar
        NSLayoutConstraint.activate([
            childView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            childView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            childView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ])

        childController.didMove(toParent: self)
    }

    /// Removes the view for the empty state.
    ///
    func removeEmptyState() {
        guard let childController = emptyStateViewController,
              let childView = childController.view,
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
        state = keyword.isEmpty ? stateIfSearchKeywordIsEmpty : .syncing
    }

    /// Transition to the appropriate `State` after search results were received.
    ///
    /// See `State` for the rules.
    ///
    func transitionToResultsUpdatedState() {
        let nextState: State

        if keyword.isEmpty {
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
