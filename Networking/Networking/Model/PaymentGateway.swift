import Foundation
import Codegen

/// Represents a Payment Gateway.
///
public struct PaymentGateway: Equatable, GeneratedFakeable, GeneratedCopiable {

    /// Features for payment gateway.
    ///
    public enum Feature: Equatable {
        case products
        case refunds
        case custom(raw: String)
    }

    /// Setting for a payment gateway
    ///
    public struct Setting: Equatable, GeneratedCopiable, GeneratedFakeable {
        public let settingID: String
        public let value: String

        public init(settingID: String,
                    value: String) {
            self.settingID = settingID
            self.value = value
        }
    }

    /// Site identifier.
    ///
    public let siteID: Int64

    /// Gateway Identifier.
    ///
    public let gatewayID: String

    /// Title for the payment gateway.
    ///
    public let title: String

    /// Description of the payment gateway.
    ///
    public let description: String

    /// Whether the payment gateway is enabled on the site or not.
    ///
    public let enabled: Bool

    /// List of features the payment gateway supports.
    ///
    public let features: [Feature]

    /// Instructions shown to the customer after purchase.
    ///
    public let instructions: String?

    public init(siteID: Int64,
                gatewayID: String,
                title: String,
                description: String,
                enabled: Bool,
                features: [Feature],
                instructions: String?) {
        self.siteID = siteID
        self.gatewayID = gatewayID
        self.title = title
        self.description = description
        self.enabled = enabled
        self.features = features
        self.instructions = instructions
    }
}

// MARK: Gateway Codable
extension PaymentGateway: Codable {

    public enum DecodingError: Error {
        case missingSiteID
    }

    private enum CodingKeys: String, CodingKey {
        case gatewayID = "id"
        case title
        case description
        case enabled
        case features = "method_supports"
        case instructions
        case settings
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw DecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let gatewayID = try container.decode(String.self, forKey: .gatewayID)
        let title = try container.decode(String.self, forKey: .title)
        let description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        let enabled = try container.decode(Bool.self, forKey: .enabled)
        let features = try container.decode([Feature].self, forKey: .features)

        // Settings can have different types for `value`, this implementation only handles `String`
        let settings = try? container.decodeIfPresent([String: Setting].self, forKey: .settings)
        let instructions = settings?[Setting.Keys.instructions]?.value

        self.init(siteID: siteID,
                  gatewayID: gatewayID,
                  title: title,
                  description: description,
                  enabled: enabled,
                  features: features,
                  instructions: instructions)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(gatewayID, forKey: .gatewayID)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(features, forKey: .features)

        guard let instructions = instructions else {
            return
        }
        let settings = [Setting.Keys.instructions: instructions]
        try container.encode(settings, forKey: .settings)
    }
}

// MARK: - Features Decodable
extension PaymentGateway.Feature: RawRepresentable, Codable {

    /// Enum containing the 'Known' Feature Keys
    ///
    private enum Keys {
        static let products = "products"
        static let refunds = "refunds"
    }

    public init?(rawValue: String) {
        switch rawValue {
        case Keys.products:
            self = .products
        case Keys.refunds:
            self = .refunds
        default:
            self = .custom(raw: rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .products:
            return Keys.products
        case .refunds:
            return Keys.refunds
        case .custom(let raw):
            return raw
        }
    }
}

// MARK: - Settings Codable
extension PaymentGateway.Setting: Codable {
    /// The known keys, which match `settingID`
    ///
    fileprivate enum Keys {
        static let title = "title"
        static let instructions = "instructions"
        static let enableForMethods = "enable_for_methods"
        static let enableForVirtual = "enable_for_virtual"
    }

    private enum CodingKeys: String, CodingKey {
        case settingID = "id"
        case value
    }
}
