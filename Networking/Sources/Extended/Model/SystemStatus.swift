/// Represent a System Status.
///
public struct SystemStatus: Decodable {
    public let plugins: SystemPlugins
    public let environment: Environment?
    public let settings: Settings?

    public init(
        plugins: SystemPlugins,
        environment: Environment?,
        settings: Settings?
    ) {
        self.plugins = plugins
        self.environment = environment
        self.settings = settings
    }

    /// The public initializer for System Status.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let plugins = try SystemPlugins(from: decoder)
        let environment = try container.decode(Environment.self, forKey: .environment)
        let settings = try container.decode(Settings.self, forKey: .settings)

        self.init(
            plugins: plugins,
            environment: environment,
            settings: settings
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

// MARK: - Settings
//
public extension SystemStatus {
    /// Details about a store's settings in its system status report.
    ///
    struct Settings: Decodable {
        /// Available in WooCommerce version 9.9.0 and later. Thus the property is optional.
        public let enabledFeatures: [String]?

        // TODO-jc: remove after having a separate model for POS eligibility system status
        public let currency: String

        enum CodingKeys: String, CodingKey {
            case enabledFeatures = "enabled_features"
            case currency
        }
    }
}

private extension SystemStatus {
    enum CodingKeys: String, CodingKey {
        case environment
        case settings
    }
}
