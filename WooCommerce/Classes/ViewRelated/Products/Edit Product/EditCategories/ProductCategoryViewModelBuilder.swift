import Foundation
import Yosemite

/// Creates `ProductCategoryViewModel` types
///
struct ProductCategoryViewModelBuilder {

    /// Represents Categories -> SubCategories relatioships
    ///
    private struct CategoryTree {

        /// Stores categories by holding a reference to it's `parentID`
        ///
        private let nodes: [Int64: [ProductCategory]]

        init(categories: [ProductCategory]) {
            nodes = Self.storageFromCategories(categories)
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
            return nodes[ProductCategory.noParentID] ?? []
        }

        /// Returns the inmediate subCategories of a given category or `nil` if there aren't any.
        ///
        func outterSubCategories(of category: ProductCategory) -> [ProductCategory]? {
            return nodes[category.categoryID]
        }
    }

    /// Returns an array of `ProductCategoryViewModel` by sorting the provided `categories` following a `Category -> SubCategory` order.
    /// Provide an array of `selectedCategories` to properly reflect the selected state in the returned view model array.
    ///
    static func viewModels(from categories: [ProductCategory], selectedCategories: [ProductCategory]) -> [ProductCategoryViewModel] {
        // Create tree structure
        let tree = CategoryTree(categories: categories)

        // For each root category, get all sub-categories and return a flattened array of view models
        let viewModels = tree.rootCategories.flatMap { category -> [ProductCategoryViewModel] in
            return flattenViewModels(of: category, in: tree, selectedCategories: selectedCategories)
        }

        return viewModels
    }

    /// Recursively return all sub-categories view models of a given category in a given tree.
    /// Provide an array of `selectedCategories` to properly reflect the selected state in the returned view model array.
    ///
    private static func flattenViewModels(of category: ProductCategory,
                                          in tree: CategoryTree,
                                          selectedCategories: [ProductCategory],
                                          depthLevel: Int = 0) -> [ProductCategoryViewModel] {

        // View model for the main category
        let categoryViewModel = viewModel(for: category, selectedCategories: selectedCategories, indentationLevel: depthLevel)

        // Base case, return the single view model when a category doesn't have any sub-categories
        guard let outterSubCategories = tree.outterSubCategories(of: category) else {
            return [categoryViewModel]
        }

        // Return the main categoryViewModel + all possible sub-categories VMs by calling this function recursively
        return [categoryViewModel] + outterSubCategories.flatMap { outterSubCategory -> [ProductCategoryViewModel] in

            // Increase the `depthLevel` to properly track the view model indentation level
            return flattenViewModels(of: outterSubCategory, in: tree, selectedCategories: selectedCategories, depthLevel: depthLevel + 1)
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
