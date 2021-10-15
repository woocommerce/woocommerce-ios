import Foundation
import Yosemite

/// This protocol should conformed by those classes that are going to handle the presentation of a `ProductCategoryList` view
///
protocol ProductCategoryListViewModelProtocol: AnyObject {
    /// Array of view models to be rendered by the View Controller.
    ///
    var categoryViewModels: [ProductCategoryCellViewModel] { get }

    /// Product categories selected by the user
    ///
    var selectedCategories: [ProductCategory] { get set }

    /// Initialisation with the site Id related to the categories
    ///
    init(siteID: Int64)

    /// Triggers a fetch of categories
    ///
    func performFetch()

    /// Retry product categories synchronization when `syncCategoriesState` is on a `.failed` state.
    ///
    func retryCategorySynchronization(retryToken: ProductCategoryListViewModel.RetryToken)

    /// Observes and notifies of changes made to product categories. the current state will be dispatched upon subscription.
    ///
    func observeCategoryListStateChanges(onStateChanges: @escaping (ProductCategoryListViewModel.SyncingState) -> Void)

    /// Select or Deselect a category
    ///
    func selectOrDeselectCategory(index: Int)

    /// Updates  `categoryViewModels` after a state change.
    ///
    func updateViewModelsArray()
}
