import Foundation
import Yosemite

/// Protocol for configuring a booking list selector with different entity types.
/// Provides all necessary configuration for fetching, displaying, and syncing list items.
protocol ListSyncable {
    associatedtype StorageType: ResultsControllerMutableType
    associatedtype ModelType: Equatable & Hashable where ModelType == StorageType.ReadOnlyType

    var siteID: Int64 { get }
    var title: String { get }
    var emptyStateMessage: String { get }

    // MARK: - ResultsController Configuration

    /// Creates the predicate for filtering storage objects
    func createPredicate() -> NSPredicate

    /// Creates sort descriptors for ordering results
    func createSortDescriptors() -> [NSSortDescriptor]

    // MARK: - Sync Configuration

    /// Creates the action to sync items from remote
    func createSyncAction(pageNumber: Int, pageSize: Int, completion: @escaping (Result<Bool, Error>) -> Void) -> Action

    // MARK: - Model Conversion

    /// Converts storage object to model object
    func convert(_ storage: StorageType) -> ModelType

    // MARK: - Display Configuration

    /// Returns the display name for an item
    func displayName(for item: ModelType) -> String
}
