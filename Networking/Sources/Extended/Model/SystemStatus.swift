/// Represent a System Status.
///
public struct SystemStatus: Decodable {
    public let plugins: SystemPlugins
    public let environment: Environment?

    public init(
        plugins: SystemPlugins,
        environment: Environment?,
    ) {
        self.plugins = plugins
        self.environment = environment
    }

    /// The public initializer for System Status.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let plugins = try SystemPlugins(from: decoder)
        let environment = try container.decode(Environment.self, forKey: .environment)

        self.init(
            plugins: plugins,
            environment: environment,
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
        case environment
    }
}
