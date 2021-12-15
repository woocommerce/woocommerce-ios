/// Represent a System Status.
///
public struct SystemStatus: Decodable {
    let activePlugins: [SystemPlugin]
    let inactivePlugins: [SystemPlugin]
    let environment: Environment?
    let database: Database?
    let dropinPlugins: [SystemPlugin]
    let mustUsePlugins: [SystemPlugin]

    public init(
        activePlugins: [SystemPlugin],
        inactivePlugins: [SystemPlugin],
        environment: Environment?,
        database: Database?,
        dropinPlugins: [SystemPlugin],
        mustUsePlugins: [SystemPlugin]
    ) {
        self.activePlugins = activePlugins
        self.inactivePlugins = inactivePlugins
        self.environment = environment
        self.database = database
        self.dropinPlugins = dropinPlugins
        self.mustUsePlugins = mustUsePlugins
    }

    /// The public initializer for System Status.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let activePlugins = try container.decode([SystemPlugin].self, forKey: .activePlugins)
        let inactivePlugins = try container.decode([SystemPlugin].self, forKey: .inactivePlugins)
        let environment = try container.decodeIfPresent(Environment.self, forKey: .environment)
        let database = try container.decodeIfPresent(Database.self, forKey: .database)

        let dropinMustUsePlugins = try container.nestedContainer(keyedBy: DropinMustUserPluginsCodingKeys.self, forKey: .dropinMustUsePlugins)
        let dropinPlugins = try dropinMustUsePlugins.decode([SystemPlugin].self, forKey: .dropins)
        let mustUsePlugins = try dropinMustUsePlugins.decode([SystemPlugin].self, forKey: .mustUsePlugins)

        self.init(
            activePlugins: activePlugins,
            inactivePlugins: inactivePlugins,
            environment: environment,
            database: database,
            dropinPlugins: dropinPlugins,
            mustUsePlugins: mustUsePlugins
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

    enum DropinMustUserPluginsCodingKeys: String, CodingKey {
        case dropins
        case mustUsePlugins = "mu_plugins"
    }
}
