/// A struct representing a reader update.
public struct CardReaderSoftwareUpdate {
    public init(estimatedUpdateTime: UpdateTimeEstimate, deviceSoftwareVersion: String) {
        self.estimatedUpdateTime = estimatedUpdateTime
        self.deviceSoftwareVersion = deviceSoftwareVersion
    }

    /// The estimated amount of time for the update.
    public let estimatedUpdateTime: UpdateTimeEstimate

    /// The target version for the update.
    public let deviceSoftwareVersion: String
}
