import Foundation

/// Protocol for checking POS catalog eligibility
/// This allows Yosemite (lower layer) to work with eligibility services from higher layers like PointOfSale
public protocol POSCatalogEligibilityChecking {
    /// Check if the catalog is eligible for syncing
    /// This includes size limits, feature flags, and other eligibility criteria
    /// - Returns: true if eligible to sync, false otherwise
    func isCatalogEligibleForSync() async -> Bool
}
