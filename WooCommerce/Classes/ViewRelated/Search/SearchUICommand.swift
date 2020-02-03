import UIKit
import Yosemite

/// An interface for search UI associated with a generic model and cell view model.
protocol SearchUICommand {
    associatedtype Model
    associatedtype CellViewModel

    /// The placeholder of the search bar.
    var searchBarPlaceholder: String { get }

    /// Displayed when there are no search results.
    var emptyStateText: String { get }

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
    func didSelectSearchResult(model: Model, from viewController: UIViewController)

    /// The Accessibility Identifier for the search bar
    var searchBarAccessibilityIdentifier: String { get }

    /// The Accessibility Identifier for the cancel button
    var cancelButtonAccessibilityIdentifier: String { get }
}
