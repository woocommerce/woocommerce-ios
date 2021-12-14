/// Represent a System Status.
///
public struct SystemStatus: Decodable {
    let activePlugins: [SystemPlugin]
    let inactivePlugins: [SystemPlugin]
    let environment: Environment

    public init(
        activePlugins: [SystemPlugin],
        inactivePlugins: [SystemPlugin],
        environment: Environment
    ) {
        self.activePlugins = activePlugins
        self.inactivePlugins = inactivePlugins
        self.environment = environment
    }

    /// The public initializer for System Status.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let activePlugins = try container.decode([SystemPlugin].self, forKey: .activePlugins)
        let inactivePlugins = try container.decode([SystemPlugin].self, forKey: .inactivePlugins)
        let environment = try container.decode(Environment.self, forKey: .environment)

        self.init(
            activePlugins: activePlugins,
            inactivePlugins: inactivePlugins,
            environment: environment
        )
    }
}

private extension SystemStatus {
    enum CodingKeys: String, CodingKey {
        case activePlugins = "active_plugins"
        case inactivePlugins = "inactive_plugins"
        case dropinMustUsePlugins = "dropins_mu_plugins"
        case environment
        case database
        case theme
        case settings
        case pages
        case postTypeCounts = "post_type_counts"
    }
}
