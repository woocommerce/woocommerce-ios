import Foundation

/// Used to filter bookings by team members
///
public struct BookingTeamMemberFilter: Codable, Hashable {
    /// ID of the team member (booking resource)
    ///
    public let resourceID: Int64

    /// Name of the team member
    ///
    public let name: String

    public init(resourceID: Int64, name: String) {
        self.resourceID = resourceID
        self.name = name
    }
}
