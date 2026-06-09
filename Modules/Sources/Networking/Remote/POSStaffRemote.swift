import Foundation

/// `POSStaff` remote endpoints.
///
public final class POSStaffRemote: Remote {

    /// Fetches the POS staff list for the given site. Requires the device user to hold
    /// `manage_woocommerce` server-side (admin / shop_manager).
    ///
    public func fetchStaff(siteID: Int64) async throws -> [POSStaffMember] {
        let request = JetpackRequest(
            wooApiVersion: .wcPosV1,
            method: .get,
            siteID: siteID,
            path: Path.staff,
            availableAsRESTRequest: true
        )
        let mapper = ListMapper<POSStaffMember>(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }
}

private extension POSStaffRemote {
    enum Path {
        static let staff = "staff"
    }
}
