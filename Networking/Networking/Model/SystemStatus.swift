/// Represent a System Status.
///
public struct SystemStatus: Decodable {
    let activePlugins: [SystemPlugin]
    let inactivePlugins: [SystemPlugin]
    let environment: Environment?
    let database: Database?
    let dropinPlugins: [DropinMustUsePlugin]
    let mustUsePlugins: [DropinMustUsePlugin]
    let theme: Theme?
    let settings: Settings?
    let pages: [Page]
    let postTypeCounts: [PostTypeCount]
    let security: Security?

    public init(
        activePlugins: [SystemPlugin],
        inactivePlugins: [SystemPlugin],
        environment: Environment?,
        database: Database?,
        dropinPlugins: [DropinMustUsePlugin],
        mustUsePlugins: [DropinMustUsePlugin],
        theme: Theme?,
        settings: Settings?,
        pages: [Page],
        postTypeCounts: [PostTypeCount],
        security: Security?
    ) {
        self.activePlugins = activePlugins
        self.inactivePlugins = inactivePlugins
        self.environment = environment
        self.database = database
        self.dropinPlugins = dropinPlugins
        self.mustUsePlugins = mustUsePlugins
        self.theme = theme
        self.settings = settings
        self.pages = pages
        self.postTypeCounts = postTypeCounts
        self.security = security
    }

    /// The public initializer for System Status.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let activePlugins = try container.decode([SystemPlugin].self, forKey: .activePlugins)
        let inactivePlugins = try container.decode([SystemPlugin].self, forKey: .inactivePlugins)
        let environment = try container.decodeIfPresent(Environment.self, forKey: .environment)
        let database = try container.decodeIfPresent(Database.self, forKey: .database)

        let dropinMustUsePlugins = try? container.nestedContainer(keyedBy: DropinMustUserPluginsCodingKeys.self, forKey: .dropinMustUsePlugins)
        let dropinPlugins = try dropinMustUsePlugins?.decodeIfPresent([DropinMustUsePlugin].self, forKey: .dropins) ?? []
        let mustUsePlugins = try dropinMustUsePlugins?.decodeIfPresent([DropinMustUsePlugin].self, forKey: .mustUsePlugins) ?? []

        let theme = try container.decodeIfPresent(Theme.self, forKey: .theme)
        let settings = try container.decodeIfPresent(Settings.self, forKey: .settings)
        let pages = try container.decodeIfPresent([Page].self, forKey: .pages) ?? []
        let postTypeCounts = try container.decodeIfPresent([PostTypeCount].self, forKey: .postTypeCounts) ?? []
        let security = try container.decodeIfPresent(Security.self, forKey: .security)

        self.init(
            activePlugins: activePlugins,
            inactivePlugins: inactivePlugins,
            environment: environment,
            database: database,
            dropinPlugins: dropinPlugins,
            mustUsePlugins: mustUsePlugins,
            theme: theme,
            settings: settings,
            pages: pages,
            postTypeCounts: postTypeCounts,
            security: security
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
        case security
    }

    enum DropinMustUserPluginsCodingKeys: String, CodingKey {
        case dropins
        case mustUsePlugins = "mu_plugins"
    }
}
