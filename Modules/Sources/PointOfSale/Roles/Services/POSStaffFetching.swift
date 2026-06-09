import struct Networking.POSStaffMember

/// Fetches the POS staff list for a site. The concrete implementation (`POSStaffAdaptor`) lives in
/// the app target and maps Networking errors to `POSStaffFetchError`.
public protocol POSStaffFetching {
    func fetchStaff(siteID: Int64) async throws(POSStaffFetchError) -> [POSStaffMember]
}
