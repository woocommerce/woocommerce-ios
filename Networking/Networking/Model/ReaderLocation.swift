/// Represent a Reader Location Entity.
///
public struct ReaderLocation: Decodable, Equatable {
    /// WordPress.com Site Identifier.
    ///
    public let siteID: Int64

    /// Location id.
    public let id: String

    /// Display name
    public let displayName: String

    public init(siteID: Int64,
                id: String,
                displayName: String) {
        self.siteID = siteID
        self.id = id
        self.displayName = displayName
    }
}
