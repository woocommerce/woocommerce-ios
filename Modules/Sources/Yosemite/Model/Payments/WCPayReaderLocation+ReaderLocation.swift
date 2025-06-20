import Networking

public extension RemoteReaderLocation {
    /// Maps a WCPayReaderLocation into the ReaderLocation struct
    ///
    func toReaderLocation(siteID: Int64) -> ReaderLocation {
        return ReaderLocation(
            siteID: siteID,
            id: locationID,
            displayName: displayName
        )
    }
}
