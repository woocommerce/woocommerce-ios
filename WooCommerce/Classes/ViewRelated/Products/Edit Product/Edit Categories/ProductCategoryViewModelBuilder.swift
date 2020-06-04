import Foundation
import Yosemite

// MARK: ViewModel Builder
extension ProductCategoryListViewModel {

    /// Creates `ProductCategoryCellViewModel` types
    ///
    struct CellViewModelBuilder {

        /// Represents Categories -> SubCategories relatioships
        ///
        private struct CategoryTree {

            /// Stores categories by holding a reference to it's `parentID`
            ///
            private let nodes: [Int64: [ProductCategory]]

            init(categories: [ProductCategory]) {
                nodes = Self.nodesFromCategories(categories)
            }

            /// Returns a dictionary  where each key holds a category `parentID` each value an array of subcategories.
            ///
            private static func nodesFromCategories(_ productCategories: [ProductCategory]) -> [Int64: [ProductCategory]] {
                return productCategories.reduce(into: [Int64: [ProductCategory]]()) { (result, category) in
                    var children = result[category.parentID] ?? []
                    children.append(category)
                    result[category.parentID] = children
                }
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

        /// Returns an array of `ProductCategoryCellViewModel` by sorting the provided `categories` following a `Category -> SubCategory` order.
        /// Provide an array of `selectedCategories` to properly reflect the selected state in the returned view model array.
        ///
        static func viewModels(from categories: [ProductCategory], selectedCategories: [ProductCategory]) -> [ProductCategoryCellViewModel] {
            // Create tree structure
            let tree = CategoryTree(categories: categories)

            // For each root category, get all sub-categories and return a flattened array of view models
            let viewModels = tree.rootCategories.flatMap { category -> [ProductCategoryCellViewModel] in
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
                                              depthLevel: Int = 0) -> [ProductCategoryCellViewModel] {

            // View model for the main category
            let categoryViewModel = viewModel(for: category, selectedCategories: selectedCategories, indentationLevel: depthLevel)

            // Base case, return the single view model when a category doesn't have any sub-categories
            guard let outterSubCategories = tree.outterSubCategories(of: category) else {
                return [categoryViewModel]
            }

            // Return the main categoryViewModel + all possible sub-categories VMs by calling this function recursively
            return [categoryViewModel] + outterSubCategories.flatMap { outterSubCategory -> [ProductCategoryCellViewModel] in

                // Increase the `depthLevel` to properly track the view model indentation level
                return flattenViewModels(of: outterSubCategory, in: tree, selectedCategories: selectedCategories, depthLevel: depthLevel + 1)
            }
        }

        /// Return a view model for an specific category, indentation level and `selectedCategories` array
        ///
        private static func viewModel(for category: ProductCategory,
                                      selectedCategories: [ProductCategory],
                                      indentationLevel: Int) -> ProductCategoryCellViewModel {
            let isSelected = selectedCategories.contains(category)
            return ProductCategoryCellViewModel(name: category.name, isSelected: isSelected, indentationLevel: indentationLevel)
        }
    }
}
