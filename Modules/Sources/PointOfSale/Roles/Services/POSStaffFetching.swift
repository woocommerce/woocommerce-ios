import struct Networking.POSStaffMember

/// Fetches the POS staff list for the given site. The concrete impl lives in the app target
/// (`POSStaffAdaptor`) and wraps `POSStaffRemote`. Errors are translated to `POSStaffFetchError`
/// at the adaptor so the authenticator and session can branch by intent without coupling to
/// Networking error types.
///
public protocol POSStaffFetching: Sendable {
    func fetchStaff(siteID: Int64) async throws(POSStaffFetchError) -> [POSStaffMember]
}
