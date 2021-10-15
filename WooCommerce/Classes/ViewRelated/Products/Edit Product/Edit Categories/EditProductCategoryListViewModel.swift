import Foundation
import Yosemite

/// View Model for the `EditProductCategory` view. Extends the presentation of a list of categories by handling the adition of a new category.
///
final class EditProductCategoryListViewModel {

    /// The shown product category list view model
    ///
    private let baseProductCategoryListViewModel: ProductCategoryListViewModel

    private let product: Product
    var selectedCategories: [ProductCategory] {
        get {
            baseProductCategoryListViewModel.selectedCategories
        }
        set {
            baseProductCategoryListViewModel.selectedCategories = newValue
        }
    }

    init(product: Product, baseProductCategoryListViewModel: ProductCategoryListViewModel) {
        self.product = product
        self.baseProductCategoryListViewModel = baseProductCategoryListViewModel

        self.selectedCategories = product.categories
    }

    /// Add a new category added remotely, and that will be selected
    ///
    func addAndSelectNewCategory(category: ProductCategory) {
        selectedCategories.append(category)
        baseProductCategoryListViewModel.updateViewModelsArray()
    }

    /// Informs of wether there are still changes that were not commited
    ///
    func hasUnsavedChanges() -> Bool {
        return product.categories.sorted() != selectedCategories.sorted()
    }
}
