import Foundation

/// An encodable/decodable data structure used to save the state of a feedback the app requests
///
public struct FeedbackSettings: Codable, Equatable {
    /// Lists all the possible scenarios that a feedback could be in
    ///
    public enum Status: Equatable {
        case pending
        case dismissed
        case given(Date)
    }

    /// Name of the feedback, for identity purposes
    ///
    public let name: FeedbackType

    /// State of the feedback
    ///
    public let status: Status

    public init(name: FeedbackType, status: Status) {
        self.name = name
        self.status = status
    }
}

// MARK: Codable Conformance
//
extension FeedbackSettings.Status: Codable {

    /// Should match `FeedbackSettings.Status`
    ///
    private enum EnumKey: String, Codable {
        case pending
        case dismissed
        case given
    }

    private enum CodingKeys: CodingKey {
        case value
        case associatedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try container.decode(EnumKey.self, forKey: .value)
        switch rawValue {
        case .pending:
            self = .pending
        case .dismissed:
            self = .dismissed
        case .given:
            let date = try container.decode(Date.self, forKey: .associatedValue)
            self = .given(date)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .pending:
            try container.encode(EnumKey.pending, forKey: .value)
        case .dismissed:
            try container.encode(EnumKey.dismissed, forKey: .value)
        case .given(let date):
            try container.encode(EnumKey.given, forKey: .value)
            try container.encode(date, forKey: .associatedValue)
        }
    }
}
