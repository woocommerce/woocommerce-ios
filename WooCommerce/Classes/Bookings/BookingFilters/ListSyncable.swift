import Foundation
import Yosemite

/// Protocol for configuring a list selector with different entity types.
/// Provides all necessary configuration for fetching, displaying, and syncing list items.
protocol ListSyncable {
    associatedtype StorageType: ResultsControllerMutableType
    associatedtype ModelType: Equatable & Hashable where ModelType == StorageType.ReadOnlyType
    associatedtype ListFilterType: FilterType & Equatable

    var title: String { get }
    var emptyStateMessage: String { get }
    var emptyItemTitlePlaceholder: String? { get }
    var searchConfiguration: ListSearchConfiguration? { get }
    var selectionDisabledMessage: String? { get }

    // MARK: - ResultsController Configuration

    /// Creates the predicate for filtering storage objects
    func createPredicate() -> NSPredicate

    /// Creates sort descriptors for ordering results
    func createSortDescriptors() -> [NSSortDescriptor]

    // MARK: - Sync Configuration

    /// Creates the action to sync items from remote
    func createSyncAction(pageNumber: Int, pageSize: Int, completion: @escaping (Result<Bool, Error>) -> Void) -> Action

    /// Creates the action to search items with keyword
    func createSearchAction(keyword: String, pageNumber: Int, pageSize: Int, completion: @escaping (Result<Bool, Error>) -> Void) -> Action

    /// Creates the predicate for filtering search results
    /// - Parameter keyword: The search keyword
    /// - Returns: A predicate to filter storage objects by search results, or nil if search predicate is not needed
    func createSearchPredicate(keyword: String) -> NSPredicate?

    // MARK: - Display Configuration

    /// Returns the display name for an item
    func displayName(for item: ModelType) -> String

    /// Returns the description for an item
    func description(for item: ModelType) -> String?

    /// Checks whether the specified item can be selected
    func selectionEnabled(for item: ModelType) -> Bool

    /// Returns the filter type for an item
    func filterItem(for item: ModelType) -> ListFilterType
}

struct ListSearchConfiguration {
    let searchPrompt: String
    let emptySearchTitle: String
    let emptySearchDescription: String
}
