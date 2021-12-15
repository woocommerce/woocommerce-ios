/// Represent a System Status.
///
public struct SystemStatus: Decodable {
    let activePlugins: [SystemPlugin]
    let inactivePlugins: [SystemPlugin]
    let environment: Environment?
    let database: Database?

    public init(
        activePlugins: [SystemPlugin],
        inactivePlugins: [SystemPlugin],
        environment: Environment?,
        database: Database?
    ) {
        self.activePlugins = activePlugins
        self.inactivePlugins = inactivePlugins
        self.environment = environment
        self.database = database
    }

    /// The public initializer for System Status.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let activePlugins = try container.decode([SystemPlugin].self, forKey: .activePlugins)
        let inactivePlugins = try container.decode([SystemPlugin].self, forKey: .inactivePlugins)
        let environment = try container.decodeIfPresent(Environment.self, forKey: .environment)
        let database = try container.decodeIfPresent(Database.self, forKey: .database)

        self.init(
            activePlugins: activePlugins,
            inactivePlugins: inactivePlugins,
            environment: environment,
            database: database
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
