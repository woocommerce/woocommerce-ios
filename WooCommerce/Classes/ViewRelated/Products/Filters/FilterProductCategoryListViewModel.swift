import Foundation
import Yosemite

/// Generates a cell view model for the "Any" selection cell, that is, when there is no category selected.
///
fileprivate extension ProductCategoryCellViewModel {
    static func anyCategoryCellViewModel(isSelected: Bool) -> ProductCategoryCellViewModel {
        ProductCategoryCellViewModel(categoryID: nil,
                                     name: NSLocalizedString("Any", comment: "Title when there is no filter set."),
                                     isSelected: isSelected,
                                     indentationLevel: 0)
    }
}

/// This class acts as a decorator to the base `ProductCategoryListViewModel`,
/// extending by adding a new row on top of the categories list, that can be used to unselect any category.
///
final class FilterProductCategoryListViewModel: ProductCategoryListViewModelProtocol {
    var categoryViewModels: [ProductCategoryCellViewModel] = []

    /// Selected categories by the user. The value is the same as the base view model
    var selectedCategories: [ProductCategory] {
        get {
            baseViewModel.selectedCategories
        }
        set {
            baseViewModel.selectedCategories = newValue
        }

    }


    /// Holds a reference to the fixed "Any" cell view model on top of the list
    ///
    private var anyCategoryViewModel = ProductCategoryCellViewModel.anyCategoryCellViewModel(isSelected: true)

    /// Base view model decorated by this class
    ///
    private let baseViewModel: ProductCategoryListViewModel
    private var onSyncStateChange: ((ProductCategoryListViewModel.SyncingState) -> Void)?

    init(siteID: Int64) {
        baseViewModel = ProductCategoryListViewModel(siteID: siteID, enforceUniqueSelection: true)
    }

    /// Trigger a fetch via the base view model
    ///
    func performFetch() {
        baseViewModel.performFetch()
    }

    /// Retries synchronization via the base view model
    ///
    func retryCategorySynchronization(retryToken: ProductCategoryListViewModel.RetryToken) {
        baseViewModel.retryCategorySynchronization(retryToken: retryToken)
    }

    /// Listens to the base view model changes, reacts to it and notifies any observer
    ///
    func observeCategoryListStateChanges(onStateChanges: @escaping (ProductCategoryListViewModel.SyncingState) -> Void) {
        onSyncStateChange = onStateChanges
        baseViewModel.observeCategoryListStateChanges { [weak self] syncState in
            self?.updateViewModelsArray()
            self?.onSyncStateChange?(syncState)
        }
    }

    /// Reacts to the selection of any category by handling the case if the first row was selected
    /// (Any Category) or passing the value to the base view model otherwise
    ///
    func selectOrDeselectCategory(index: Int) {
        defer { updateViewModelsArray() }

        guard index != 0 else {
            selectedCategories = []
            anyCategoryViewModel = ProductCategoryCellViewModel.anyCategoryCellViewModel(isSelected: true)
            updateViewModelsArray()

            return
        }

        anyCategoryViewModel = ProductCategoryCellViewModel.anyCategoryCellViewModel(isSelected: false)

        baseViewModel.selectOrDeselectCategory(index: index - 1)
    }

    /// Updates view models adding the first `Any Category` row
    ///
    func updateViewModelsArray() {
        baseViewModel.updateViewModelsArray()
        categoryViewModels = [anyCategoryViewModel] + baseViewModel.categoryViewModels
    }
}
