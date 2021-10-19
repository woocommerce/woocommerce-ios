import Foundation
import Yosemite

/// View Model for the `EditProductCategory` view. Extends the presentation of a list of categories by handling the adition of a new category.
///
final class EditProductCategoryListViewModel {
    /// Title for the add category button
    ///
    let addCategoryButtonTitle: String = .addCategoryButtonTitle

    /// Title for the screen
    ///
    let screenTitle: String = .screenTitle

    /// Title for the done button
    ///
    let doneButtonTitle: String = .doneButtonTitle

    /// The shown product category list view model
    ///
    private let baseProductCategoryListViewModel: ProductCategoryListViewModel

    private let product: Product
    private let onCompletion: EditProductCategoryListViewController.Completion

    init(product: Product,
         baseProductCategoryListViewModel: ProductCategoryListViewModel,
         completion: @escaping EditProductCategoryListViewController.Completion) {
        self.product = product
        self.baseProductCategoryListViewModel = baseProductCategoryListViewModel
        onCompletion = completion
    }

    /// Add a new category added remotely, and that will be selected
    ///
    func addAndSelectNewCategory(category: ProductCategory) {
        baseProductCategoryListViewModel.selectedCategories.append(category)
        baseProductCategoryListViewModel.updateViewModelsArray()
        baseProductCategoryListViewModel.reloadData()
    }

    /// Reacts to the completion action
    ///
    func doneButtonTapped() {
        onCompletion(baseProductCategoryListViewModel.selectedCategories)
    }

    /// Informs of wether there are still changes that were not commited
    ///
    func hasUnsavedChanges() -> Bool {
        return product.categories.sorted() != baseProductCategoryListViewModel.selectedCategories.sorted()
    }
}

// MARK: - Localization

private extension String {
    static let addCategoryButtonTitle = NSLocalizedString("Add Category", comment: "Action to add category on the Product Categories screen")

    static let screenTitle = NSLocalizedString("Categories", comment: "Edit product categories screen - Screen title")

    static let doneButtonTitle = NSLocalizedString("Done",
                                                   comment: "Edit product categories screen - button title to apply categories selection")
}
