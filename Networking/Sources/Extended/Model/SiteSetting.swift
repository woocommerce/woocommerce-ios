import Foundation
import Codegen

/// Represents a specific setting entity for a specific site.
///
public struct SiteSetting: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {
    public let siteID: Int64
    public let settingID: String
    public let label: String
    public let settingDescription: String
    public let value: String
    public let settingGroupKey: String

    /// OrderNote struct initializer.
    ///
    public init(siteID: Int64, settingID: String, label: String, settingDescription: String, value: String, settingGroupKey: String) {
        self.siteID = siteID
        self.settingID = settingID
        self.label = label
        self.settingDescription = settingDescription
        self.value = value
        self.settingGroupKey = settingGroupKey
    }

    /// The public initializer for SiteSetting.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw SiteSettingError.missingSiteID
        }
        guard let settingGroupKey = decoder.userInfo[.settingGroupKey] as? String else {
            throw SiteSettingError.missingSettingGroupKey
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let settingID = try container.decode(String.self, forKey: .settingID)
        let label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        let settingDescription = try container.decodeIfPresent(String.self, forKey: .settingDescription) ?? ""
        let responseType = try container.decodeIfPresent(ResponseType.self, forKey: .type) ?? .unknown
        var value = ""
        if responseType.isSupported {
            if let stringValue = try? container.decode(String.self, forKey: .value) {
                value = stringValue
            } else {
                DDLogWarn("⚠️ Could not successfully decode SiteSetting value for \(settingID)")
            }
        }
        self.init(siteID: siteID, settingID: settingID, label: label, settingDescription: settingDescription, value: value, settingGroupKey: settingGroupKey)
    }
}
/// Defines all of the response types of SiteSettings options
/// See: https://woocommerce.github.io/woocommerce-rest-api-docs/#setting-option-properties
///
private extension SiteSetting {
    enum ResponseType: String, Codable {
        case text
        case email
        case number
        case color
        case password
        case textarea
        case select
        case multiselect
        case radio
        case imageWidth = "image_width"
        case checkbox
        // For types not contemplated by the API
        case unknown

        var isSupported: Bool {
            switch self {
            case .multiselect:
                return false
            default:
                return true
            }
        }
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
        case type               = "type"
    }
}


// MARK: - Comparable Conformance
//
extension SiteSetting: Comparable {
    public static func < (lhs: SiteSetting, rhs: SiteSetting) -> Bool {
        return lhs.settingID < rhs.settingID ||
            (lhs.settingID == rhs.settingID && lhs.label < rhs.label)
    }
}


// MARK: - Decoding Errors
//
enum SiteSettingError: Error {
    case missingSiteID
    case missingSettingGroupKey
}
