import Foundation

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
