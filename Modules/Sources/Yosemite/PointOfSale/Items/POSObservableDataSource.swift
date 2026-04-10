// periphery:ignore:all
import Foundation

/// Protocol for observable data sources that provide POS items with automatic updates
public protocol POSObservableDataSourceProtocol {
    /// Current products mapped to POSItems
    var productItems: [POSItem] { get }

    /// Current variations for the selected parent product mapped to POSItems
    var variationItems: [POSItem] { get }

    /// Loading state for products
    var isLoadingProducts: Bool { get }

    /// Loading state for variations
    var isLoadingVariations: Bool { get }

    /// Whether more products are available to load
    var hasMoreProducts: Bool { get }

    /// Whether more variations are available for current parent
    var hasMoreVariations: Bool { get }

    /// Error from product loading, if any
    var productError: Error? { get }

    /// Error from variation loading, if any
    var variationError: Error? { get }

    /// Loads the first page of products
    func loadProducts()

    /// Loads the next page of products
    func loadMoreProducts()

    /// Loads variations for a specific parent product
    func loadVariations(for parentProduct: POSVariableParentProduct)

    /// Loads more variations for the current parent product
    func loadMoreVariations()
}
