import UIKit
import Yosemite

/// An interface for search UI associated with a generic model and cell view model.
protocol SearchUICommand {
    associatedtype Model
    associatedtype CellViewModel
    associatedtype EmptyStateViewControllerType: UIViewController = EmptyStateViewController

    /// The placeholder of the search bar.
    var searchBarPlaceholder: String { get }

    /// A closure to resynchronize models if the data source changes (e.g. when the filter changes in products search).
    var resynchronizeModels: (() -> Void) { get set }

    associatedtype ResultsControllerModel: ResultsControllerMutableType where ResultsControllerModel.ReadOnlyType == Model
    /// Creates a results controller for the search results. The result model's readonly type matches the search result model.
    func createResultsController() -> ResultsController<ResultsControllerModel>

    /// The controller of the view to show if there is no text entered in the search bar.
    ///
    /// This will only be called once when `SearchViewController` is loaded and will be retained
    /// until `SearchViewController` is deallocated.
    ///
    /// The `view` of this controller will be added and constrained to the same size as the
    /// `SearchViewController`'s `tableView`.
    ///
    /// If `nil`, the search results tableView will be shown as the starter instead.
    ///
    func createStarterViewController() -> UIViewController?

    /// The controller of the view to show if the search results are empty.
    ///
    /// This will only be called if `SearchViewController` receives empty results. It will be
    /// retained once it has been created.
    ///
    /// The `view` of this controller will be added and constrained to the same size as the
    /// `SearchViewController`'s `tableView` but below the search bar.
    ///
    /// If not provided, an `EmptySearchResultsViewController` will be created instead.
    ///
    func createEmptyStateViewController() -> EmptyStateViewControllerType

    /// Called before showing the `EmptyStateViewControllerType` view.
    ///
    /// This allows `SearchUICommand` implementations to customize the
    /// `EmptyStateViewControllerType` instance after a search attempt was made and the results
    /// are empty. For example, a title label can be changed to "No results for {searchKeyword}".
    ///
    /// This is optional.
    ///
    /// - Parameter viewController: The controller created in `createEmptyStateViewController`.
    ///
    func configureEmptyStateViewControllerBeforeDisplay(viewController: EmptyStateViewControllerType,
                                                        searchKeyword: String)

    /// The optional view to show between the search bar and search results table view.
    /// If `nil`, the search bar is right above the search results.
    func createHeaderView() -> UIView?

    /// Optionally configures the action button that dismisses the search UI.
    /// - Parameters:
    ///   - button: the button in the navigation bar that dismisses the search UI. Shows "Cancel" by default.
    ///   - onDismiss: called when it is ready to dismiss the search UI.
    func configureActionButton(_ button: UIButton, onDismiss: @escaping () -> Void)

    /// Creates a view model for the search result cell.
    ///
    /// - Parameter model: search result model.
    /// - Returns: a view model based on the search result model.
    func createCellViewModel(model: Model) -> CellViewModel

    /// Synchronizes the models matching a given keyword.
    func synchronizeModels(siteID: Int64,
                           keyword: String,
                           pageNumber: Int,
                           pageSize: Int,
                           onCompletion: ((Bool) -> Void)?)

    /// Called when user selects a search result.
    ///
    /// - Parameters:
    ///   - model: search result model.
    ///   - viewController: view controller where the user selects the search result.
    ///   - reloadData: called when UI reload is necessary.
    ///   - updateActionButton: called when action button update is necessary.
    func didSelectSearchResult(model: Model, from viewController: UIViewController, reloadData: () -> Void, updateActionButton: () -> Void)

    /// The Accessibility Identifier for the search bar
    var searchBarAccessibilityIdentifier: String { get }

    /// The Accessibility Identifier for the cancel button
    var cancelButtonAccessibilityIdentifier: String { get }

    /// Optionally sanitizes the search keyword.
    ///
    /// - Parameter keyword: user-entered search keyword.
    /// - Returns: sanitized search keyword.
    func sanitizeKeyword(_ keyword: String) -> String

    /// The predicate to fetch product search results based on the keyword.
    /// - Parameter keyword: search query.
    /// - Returns: predicate that is based on the search keyword.
    func searchResultsPredicate(keyword: String) -> NSPredicate
}

// MARK: - Default implementation
extension SearchUICommand {
    func configureActionButton(_ button: UIButton, onDismiss: @escaping () -> Void) {
        // If not implemented, keeps the default cancel UI/UX
    }

    func sanitizeKeyword(_ keyword: String) -> String {
        // If not implemented, returns the keyword as entered
        return keyword
    }

    func createHeaderView() -> UIView? {
        // If not implemented, returns `nil` to not show the header.
        nil
    }
}

// MARK: - SearchUICommand using EmptySearchResultsViewController

extension SearchUICommand {

    /// Creates an instance of `EmptySearchResultsViewController`
    ///
    func createEmptyStateViewController() -> EmptyStateViewController {
        EmptyStateViewController()
    }

    /// Default implementation which does not do anything.
    ///
    func configureEmptyStateViewControllerBeforeDisplay(viewController: EmptyStateViewController,
                                                        searchKeyword: String) {
        // noop
    }
}
