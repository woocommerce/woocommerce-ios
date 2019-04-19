/// Models a pair of `siteID` and Shipment Tracking Provider name
/// These entities will be serialised to a plist file
///
public struct PreselectedProvider: Codable, Equatable {
    public let siteID: Int
    public let providerName: String

    public init(siteID: Int, providerName: String) {
        self.siteID = siteID
        self.providerName = providerName
    }

    public static func == (lhs: PreselectedProvider, rhs: PreselectedProvider) -> Bool {
        return lhs.siteID == rhs.siteID
    }
}
