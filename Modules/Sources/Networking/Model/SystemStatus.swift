/// Represent a System Status.
///
public struct SystemStatus: Decodable {
    public let activePlugins: [SystemPlugin]
    public let inactivePlugins: [SystemPlugin]
    public let environment: Environment?

    public init(
        activePlugins: [SystemPlugin],
        inactivePlugins: [SystemPlugin],
        environment: Environment?
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
        let environment = try container.decodeIfPresent(Environment.self, forKey: .environment)

        self.init(
            activePlugins: activePlugins,
            inactivePlugins: inactivePlugins,
            environment: environment
        )
    }
}

public extension SystemStatus {
    /// Simplified Environment type that only contains storeID
    struct Environment: Decodable {
        public let storeID: String?

        enum CodingKeys: String, CodingKey {
            case storeID = "store_id"
        }
    }
}

private extension SystemStatus {
    enum CodingKeys: String, CodingKey {
        case activePlugins = "active_plugins"
        case inactivePlugins = "inactive_plugins"
        case environment
    }
}
