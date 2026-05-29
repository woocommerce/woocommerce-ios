import Foundation

/// Error returned by `POSStaffFetching.fetchStaff(siteID:)`. Mapped at the app-target adaptor
/// from underlying Networking errors so the authenticator and session can branch by intent.
///
public enum POSStaffFetchError: Error, Equatable {
    /// HTTP 404 / `rest_no_route`. Server-side `point_of_sale_staff` feature flag is off.
    /// The session should clear its cache and degrade to no-PIN-gating mode.
    case flagDisabledServerSide

    /// HTTP 401/403. The device admin lacks `manage_pos_staff`. Diagnostic state; downstream
    /// PRs surface this as a generic "Reach out to your administrator" message.
    case adminMissingCapability

    /// 5xx / network timeout / connectivity. Transient. Caller falls back to the existing cache.
    case transient(retryable: Bool)

    /// Response body could not be decoded. Indicates a wire-shape mismatch with the backend.
    case malformedResponse
}
