import Foundation
import Yosemite

/// View Model for the `EditProductCategory` view. Extends the presentation of a list of categories by handling the adition of a new category.
///
final class EditProductCategoryListViewModel {
    /// The shown product category list view model
    ///
    weak var baseProductCategoryListViewModel: ProductCategoryListViewModelProtocol?

    let product: Product
    var selectedCategories: [ProductCategory] {
        baseProductCategoryListViewModel?.selectedCategories ?? []
    }

    init(storesManager: StoresManager = ServiceLocator.stores, product: Product) {
        self.product = product
    }

    /// Add a new category added remotely, and that will be selected
    ///
    func addAndSelectNewCategory(category: ProductCategory) {
        baseProductCategoryListViewModel?.selectedCategories.append(category)
        baseProductCategoryListViewModel?.updateViewModelsArray()
    }

    /// Informs of wether there are still changes that were not commited
    ///
    func hasUnsavedChanges() -> Bool {
        return product.categories.sorted() != baseProductCategoryListViewModel?.selectedCategories.sorted()
    }
}
