import Foundation


/// Represents a specific setting entity for a specific site.
///
public struct SiteSetting: Decodable {
    public let siteID: Int
    public let settingID: String
    public let label: String
    public let settingDescription: String
    public let value: String

    /// OrderNote struct initializer.
    ///
    public init(siteID: Int, settingID: String, label: String, description: String, value: String) {
        self.siteID = siteID
        self.settingID = settingID
        self.label = label
        self.settingDescription = description
        self.value = value
    }

    /// The public initializer for SiteSetting.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int else {
            throw SiteSettingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let settingID = try container.decode(String.self, forKey: .settingID)
        let label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        let settingDescription = try container.decodeIfPresent(String.self, forKey: .settingDescription) ?? ""

        // Note: `value` is a mixed type per the documentation — usually a String but could be an Array, Int, etc
        // For the specific settings we are interested in, it is a String type.
        // See: https://woocommerce.github.io/woocommerce-rest-api-docs/#setting-options for more details.
        var value = ""
        if let stringValue = try? container.decode(String.self, forKey: .value) {
            value = stringValue
        } else {
            DDLogWarn("⚠️ Could not successfully decode SiteSetting value for \(settingID)")
        }

        self.init(siteID: siteID, settingID: settingID, label: label, description: settingDescription, value: value) // initialize the struct
    }
}


/// Defines all of the SiteSetting CodingKeys.
///
private extension SiteSetting {

    enum CodingKeys: String, CodingKey {
        case settingID          = "id"
        case label              = "label"
        case settingDescription = "description"
        case value              = "value"
    }
}


// MARK: - Comparable Conformance
//
extension SiteSetting: Comparable {
    public static func == (lhs: SiteSetting, rhs: SiteSetting) -> Bool {
        return lhs.settingID == rhs.settingID &&
            lhs.label == rhs.label &&
            lhs.settingDescription == rhs.settingDescription &&
            lhs.value == rhs.value
    }

    public static func < (lhs: SiteSetting, rhs: SiteSetting) -> Bool {
        return lhs.settingID < rhs.settingID ||
            (lhs.settingID == rhs.settingID && lhs.label < rhs.label)
    }

    public static func > (lhs: SiteSetting, rhs: SiteSetting) -> Bool {
        return lhs.settingID > rhs.settingID ||
            (lhs.settingID == rhs.settingID && lhs.label > rhs.label)
    }
}


// MARK: - Decoding Errors
//
enum SiteSettingError: Error {
    case missingSiteID
}
