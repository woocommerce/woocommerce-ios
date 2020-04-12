import Foundation
import Yosemite

/// Represents a row in the ProductCategoryList screen
///
struct ProductCategoryViewModel {
    /// Category name
    ///
    let name: String

    /// Category selected status
    ///
    let isSelected: Bool

    /// Level of indentation as a subcategory
    ///
    let indentationLevel: Int
}

// MARK: View Model Creation
//
extension ProductCategoryViewModel {

    /// Represents Categories -> SubCategories relatioships
    ///
    private struct CategoryTree {

        /// Stores categories by holding a reference to it's `parentID`
        ///
        private let storage: [Int64: [ProductCategory]]

        init(categories: [ProductCategory]) {
            storage = Self.storageFromCategories(categories)
        }

        /// Returns a dictionary  where each key holds a category `parentID` each value an array of subcategories.
        ///
        private static func storageFromCategories(_ productCategories: [ProductCategory]) -> [Int64: [ProductCategory]] {
            var storage: [Int64: [ProductCategory]] = [:]
            for category in productCategories {
                var subCategories = storage[category.parentID] ?? []
                subCategories.append(category)
                storage[category.parentID] = subCategories
            }
            return storage
        }

        /// Returns categories that don't have a `parentID`
        ///
        var rootCategories: [ProductCategory] {
            return storage[0] ?? []
        }

        /// Returns the inmediate subCategories of a given category or `nil` if there aren't any.
        ///
        func outterSubCategories(of category: ProductCategory) -> [ProductCategory]? {
            return storage[category.categoryID]
        }
    }

    /// Returns an array of `ProductCategoryViewModel` by sorting the provided `categories` following a `Category -> SubCategory` order.
    /// Provide an array of `selectedCategories` to properly reflect the selected state in the returned view model array.
    ///
    static func viewModels(from categories: [ProductCategory], selectedCategories: [ProductCategory]) -> [ProductCategoryViewModel] {
        // Create tree structure
        let tree = CategoryTree(categories: categories)

        // For each root category, get all sub-categories and returned a flattened array of view models
        let viewModels = tree.rootCategories.flatMap { category -> [ProductCategoryViewModel] in

            // Create view model for the root category
            let rootViewModel = viewModel(for: category, selectedCategories: selectedCategories, indentationLevel: 0)

            // Get sub-categories view models
            let traversedSubViewModels = flattenViewModels(of: category, in: tree, selectedCategories: selectedCategories)

            // Return a combined categoryVM + subCategoryVMs array
            return [rootViewModel] + traversedSubViewModels
        }
        return viewModels
    }

    /// Recursively return all sub-categories view models of a given category in a given tree.
    /// Provide an array of `selectedCategories` to properly reflect the selected state in the returned view model array.
    ///
    private static func flattenViewModels(of category: ProductCategory,
                                          in tree: CategoryTree,
                                          selectedCategories: [ProductCategory],
                                          depthLevel: Int = 1) -> [ProductCategoryViewModel] {

        // Base case, return an empty array when a category doesn't have any sub-categories
        guard let outterSubCategories = tree.outterSubCategories(of: category) else {
            return []
        }

        // For each outter sub-category call this function recursively to traverse and return all possible sub-categories view models
        // Increase the `depthLevel` to properly track the view model indentation level
        return outterSubCategories.flatMap { outterSubCategory -> [ProductCategoryViewModel] in

            // Create view model for the specific sub-category
            let outterViewModel = viewModel(for: outterSubCategory, selectedCategories: selectedCategories, indentationLevel: depthLevel)

            // Get sub-categories view models
            let traversedSubViewModels = flattenViewModels(of: outterSubCategory, in: tree, selectedCategories: selectedCategories, depthLevel: depthLevel + 1)

            // Return a combined categoryVM + subCategoryVMs array
            return [outterViewModel] + traversedSubViewModels
        }
    }

    /// Return a view model for an specific category, indentation level and `selectedCategories` array
    ///
    private static func viewModel(for category: ProductCategory,
                                  selectedCategories: [ProductCategory],
                                  indentationLevel: Int) -> ProductCategoryViewModel {
        let isSelected = selectedCategories.contains(category)
        return ProductCategoryViewModel(name: category.name, isSelected: isSelected, indentationLevel: indentationLevel)
    }
}
