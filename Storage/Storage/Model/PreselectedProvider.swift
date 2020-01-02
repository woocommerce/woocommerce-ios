/// Models a pair of `siteID` and Shipment Tracking Provider name
/// These entities will be serialised to a plist file
///
public struct PreselectedProvider: Codable, Equatable {
    public let siteID: Int64
    public let providerName: String
    public let providerURL: String?

    public init(siteID: Int64, providerName: String, providerURL: String? = nil) {
        self.siteID = siteID
        self.providerName = providerName
        self.providerURL = providerURL
    }

    public static func == (lhs: PreselectedProvider, rhs: PreselectedProvider) -> Bool {
        return lhs.siteID == rhs.siteID
    }
}
