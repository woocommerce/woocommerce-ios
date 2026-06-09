import Foundation

/// Error returned by `POSStaffFetching.fetchStaff(siteID:)`. Mapped at the app-target adaptor
/// from underlying Networking errors so the authenticator and session can branch by intent.
///
public enum POSStaffFetchError: Error, Equatable {
    /// HTTP 404 / `rest_no_route`: the staff endpoint isn't registered server-side — either a feature
    /// flag gating it is off, or the store's WooCommerce/POS version predates the endpoint. The two are
    /// indistinguishable to the client and both degrade to no-PIN-gating mode.
    case endpointUnavailable

    /// HTTP 401/403. The device admin lacks the server-side capability required to read the
    /// staff endpoint (currently `manage_woocommerce`). Diagnostic state; surfaced to the operator
    /// as a generic "Reach out to your administrator" message.
    case adminMissingCapability

    /// 5xx / network timeout / connectivity. Transient. Caller falls back to the existing cache.
    case transient(retryable: Bool)

    /// Response body could not be decoded. Indicates a wire-shape mismatch with the backend.
    case malformedResponse
}
