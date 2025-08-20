import Foundation

/// Protocol for Point of Sale catalog synchronization
///
public protocol POSCatalogSyncServiceProtocol {
    /// Syncs the entire POS catalog from a remote source
    /// Downloads products and product variations, then saves them to local storage
    /// Uses background download for large files following Apple's best practices
    ///
    func syncCatalog() async throws
}

/// Errors that can occur during catalog synchronization
///
public enum POSCatalogSyncError: Error, Equatable {
    case networkFailure
    case invalidData
    case storageFailure
    case timeout
    case unknown
}
