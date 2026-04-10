/// The type of filter when searching for products.
/// Since partial SKU search is not feasible in the regular search API due to performance reason,
/// the UI separates the search for all products and by SKU.
public enum ProductSearchFilter: String, Equatable, CaseIterable {
    /// Search for all products based on the keyword.
    case all
    /// Search for products that match the name field.
    case name
    /// Search for products that match the SKU field.
    case sku

    /// Options for searching in product selector view.
    /// `name` is omitted as it's used for bookable product filters only so far.
    public static var productSelectorOptions: [ProductSearchFilter] {
        [.all, .sku]
    }
}
