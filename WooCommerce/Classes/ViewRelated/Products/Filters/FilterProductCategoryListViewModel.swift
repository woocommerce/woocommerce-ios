import Foundation

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

final class FilterProductCategoryListViewModel: ProductCategoryListViewModelEnrichingDataSource, ProductCategoryListViewModelDelegate {
    /// Title for the view
    ///
    let title = Localization.title

    /// Holds a reference to the fixed "Any" category cell selection value so it can be used when enriching category view models
    ///
    private var anyCategoryIsSelected = true

    /// Enriches the category view models by adding the "Any" category row view model on top
    ///
    func enrichCategoryViewModels(_ viewModels: [ProductCategoryCellViewModel]) -> [ProductCategoryCellViewModel] {
        var returningViewModels = viewModels
        let anyCategoryViewModel = ProductCategoryCellViewModel.anyCategoryCellViewModel(isSelected: anyCategoryIsSelected)
        returningViewModels.insert(anyCategoryViewModel, at: 0)

        return returningViewModels
    }

    /// Reacts to a cell selection having into account that:
    ///     - Only one category selection is  allowed when filtering products, that is why categories are reset everytime a selection happens
    ///     - Because, of that, if one cell is selected (including Any on top) while selected, it stays selected.
    ///
    func viewModel(_ viewModel: ProductCategoryListViewModel, didSelectRowAt index: Int) {
        viewModel.resetSelectedCategories()
        anyCategoryIsSelected = index == 0
    }
}

private extension FilterProductCategoryListViewModel {
    enum Localization {
        static let title = NSLocalizedString("Categories", comment: "Filter product categories screen - Screen title")
    }
}
