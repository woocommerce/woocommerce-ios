import Foundation


/// Represents a specific setting Entity for a site.
///
public struct SiteSetting: Decodable {
    public let settingID: String
    public let label: String
    public let description: String
    public let value: String

    /// OrderNote struct initializer.
    ///
    public init(settingID: String, label: String, description: String, value: String) {
        self.settingID = settingID
        self.label = label
        self.description = description
        self.value = value
    }

    /// The public initializer for OrderNote.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let settingID = try container.decode(String.self, forKey: .settingID)
        let label = try container.decode(String.self, forKey: .label)
        let description = try container.decode(String.self, forKey: .description)
        let value = try container.decode(String.self, forKey: .value)

        self.init(settingID: settingID, label: label, description: description, value: value) // initialize the struct
    }
}


/// Defines all of the SiteSetting CodingKeys.
///
private extension SiteSetting {

    enum CodingKeys: String, CodingKey {
        case settingID      = "id"
        case label          = "label"
        case description    = "description"
        case value          = "value"
    }
}


// MARK: - Comparable Conformance
//
extension SiteSetting: Comparable {
    public static func == (lhs: SiteSetting, rhs: SiteSetting) -> Bool {
        return lhs.settingID == rhs.settingID &&
            lhs.label == rhs.label &&
            lhs.description == rhs.description &&
            lhs.value == rhs.value
    }

    public static func < (lhs: SiteSetting, rhs: SiteSetting) -> Bool {
        return lhs.settingID < rhs.settingID ||
            (lhs.settingID == rhs.settingID && lhs.label < rhs.label)
    }
}
