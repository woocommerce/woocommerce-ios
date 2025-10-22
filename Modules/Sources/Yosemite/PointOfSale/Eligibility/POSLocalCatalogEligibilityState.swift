import Foundation

/// Eligibility state for local catalog feature
/// Provides diagnostic information for UI display and decision-making
public enum POSLocalCatalogEligibilityState: Equatable {
    /// Local catalog is eligible for use
    case eligible

    /// Local catalog is not eligible
    case ineligible(reason: POSLocalCatalogIneligibleReason)
}

/// Reasons why local catalog is ineligible
public enum POSLocalCatalogIneligibleReason: Equatable {
    case featureFlagDisabled
    case catalogSizeTooLarge(totalCount: Int, limit: Int)
    case catalogSizeCheckFailed(underlyingError: String)
}
