import struct Yosemite.POSStaffMember

/// Backs the staff settings screen. M1 is read-only: load the latest staff snapshot and expose the
/// web "manage staff" URL (an authenticated wp-admin deep link, passed as a string the view
/// resolves). M2 will extend this protocol with in-app staff/PIN management — create / update /
/// delete staff and set / reset PIN — so the screen evolves without changing how it's injected.
///
/// `DefaultPOSStaffSettingsService` is the standard implementation; the app target supplies the
/// manage-on-web URL (see `Site.posStaffManagementAdminURL`).
public protocol POSStaffSettingsService {
    func loadStaff() async throws -> [POSStaffMember]
    var manageStaffURL: String { get }
}

/// Default `POSStaffSettingsService`: a stateless wrapper that loads staff through the injected
/// `POSStaffFetching` and exposes the host-provided manage-on-web URL string. The wp-admin URL is
/// built by the app target (see `Site.posStaffManagementAdminURL`) and passed in as data, mirroring
/// how `receiptSettingsAdminURL` flows into POS.
public struct DefaultPOSStaffSettingsService: POSStaffSettingsService {
    private let staffFetcher: POSStaffFetching
    private let siteID: Int64
    public let manageStaffURL: String

    public init(staffFetcher: POSStaffFetching, siteID: Int64, manageStaffURL: String) {
        self.staffFetcher = staffFetcher
        self.siteID = siteID
        self.manageStaffURL = manageStaffURL
    }

    public func loadStaff() async throws -> [POSStaffMember] {
        try await staffFetcher.fetchStaff(siteID: siteID)
    }
}
