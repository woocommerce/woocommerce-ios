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
    private let onCompletionCallback: EditProductCategoryListViewController.Completion

    init(product: Product,
         baseProductCategoryListViewModel: ProductCategoryListViewModel,
         completion: @escaping EditProductCategoryListViewController.Completion) {
        self.product = product
        self.baseProductCategoryListViewModel = baseProductCategoryListViewModel
        onCompletionCallback = completion
    }

    /// Add a new category added remotely, and that will be selected
    ///
    func addAndSelectNewCategory(category: ProductCategory) {
        baseProductCategoryListViewModel.addAndSelectNewCategory(category: category)
    }

    /// Reacts to the completion action
    ///
    func onCompletion() {
        onCompletionCallback(baseProductCategoryListViewModel.selectedCategories)
    }

    /// Informs of wether there are still changes that were not commited
    ///
    func hasUnsavedChanges() -> Bool {
        return product.categories.sorted() != baseProductCategoryListViewModel.selectedCategories.sorted()
    }
}

// MARK: - Localization

private extension String {
    static let addCategoryButtonTitle = NSLocalizedString("Add Category", comment: "This text appears as the navigation bar title when users are adding a new product category, and also as a button label that allows users to create a new category from the product categories screen.")

    static let screenTitle = NSLocalizedString("Categories", comment: "This text appears as a title/label for the Categories section in the product editing interface, allowing merchants to assign product categories. It's used in bottom sheet actions, composite product component options, and as a row title in the main product form.")

    static let doneButtonTitle = NSLocalizedString("Done",
                                                   comment: "Edit product categories screen - button title to apply categories selection")
}
