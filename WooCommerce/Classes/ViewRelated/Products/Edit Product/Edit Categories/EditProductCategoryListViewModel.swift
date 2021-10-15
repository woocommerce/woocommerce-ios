import Foundation
import Yosemite

/// View Model for the `EditProductCategory` view. Extends the presentation of a list of categories by handling the adition of a new category.
///
final class EditProductCategoryListViewModel {
    weak var newProductCategoryListViewModel: ProductCategoryListViewModelProtocol?

    let product: Product
    var selectedCategories: [ProductCategory] {
        newProductCategoryListViewModel?.selectedCategories ?? []
    }

    init(storesManager: StoresManager = ServiceLocator.stores, product: Product) {
        self.product = product
    }

    func addAndSelectNewCategory(category: ProductCategory) {
        newProductCategoryListViewModel?.selectedCategories.append(category)
        newProductCategoryListViewModel?.updateViewModelsArray()
    }

    func hasUnsavedChanges() -> Bool {
        return product.categories.sorted() != newProductCategoryListViewModel?.selectedCategories.sorted()
    }
}
