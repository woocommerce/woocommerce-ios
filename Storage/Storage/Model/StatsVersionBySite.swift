/// Models a wrapper of a dictionary from site ID to stats version.
/// These entities will be serialised to a plist file
///
public struct StatsVersionBySite: Codable, Equatable {
    public let statsVersionBySite: [Int: StatsVersion]

    public init(statsVersionBySite: [Int: StatsVersion]) {
        self.statsVersionBySite = statsVersionBySite
    }
}
