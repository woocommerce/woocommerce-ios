/// A struct representing a reader update.
public struct CardReaderSoftwareUpdate {
    /// The estimated amount of time for the update.
    public let estimatedUpdateTime: UpdateTimeEstimate

    /// The target version for the update.
    public let deviceSoftwareVersion: String
}
