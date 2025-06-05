/// Represent a System Status Plugins.
///
public struct SystemPlugins: Decodable {
    public let activePlugins: [SystemPlugin]
    public let inactivePlugins: [SystemPlugin]

    public init(
        activePlugins: [SystemPlugin],
        inactivePlugins: [SystemPlugin]
    ) {
        self.activePlugins = activePlugins
        self.inactivePlugins = inactivePlugins
    }

    /// The public initializer for System Status.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let activePlugins = try container.decode([SystemPlugin].self, forKey: .activePlugins)
        let inactivePlugins = try container.decode([SystemPlugin].self, forKey: .inactivePlugins)

        self.init(
            activePlugins: activePlugins,
            inactivePlugins: inactivePlugins
        )
    }
}

private extension SystemPlugins {
    enum CodingKeys: String, CodingKey {
        case activePlugins = "active_plugins"
        case inactivePlugins = "inactive_plugins"
    }
}
