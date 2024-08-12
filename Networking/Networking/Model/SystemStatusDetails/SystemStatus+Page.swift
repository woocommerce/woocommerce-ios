import Foundation

public extension SystemStatus {
    /// Subtype for details about a site's pages in system status.
    ///
    struct Page: Decodable {
        public let pageName, pageID: String
        public let pageSet, pageExists, pageVisible: Bool
        public let shortcode: String
        public let block: String?
        public let shortcodeRequired, shortcodePresent, blockPresent, blockRequired: Bool

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.pageName = try container.decodeIfPresent(String.self, forKey: .pageName) ?? ""
            /// `page_id` is sent as a number for some JSON objects in wporg login case
            self.pageID = container.failsafeDecodeIfPresent(targetType: String.self,
                                                            forKey: .pageID,
                                                            alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })]) ?? ""

            self.pageSet = try container.decodeIfPresent(Bool.self, forKey: .pageSet) ?? false
            self.pageExists = try container.decodeIfPresent(Bool.self, forKey: .pageExists) ?? false
            self.pageVisible = try container.decodeIfPresent(Bool.self, forKey: .pageVisible) ?? false

            self.shortcode = try container.decodeIfPresent(String.self, forKey: .shortcode) ?? ""
            self.block = try container.decodeIfPresent(String.self, forKey: .block) ?? ""

            self.shortcodeRequired = try container.decodeIfPresent(Bool.self, forKey: .shortcodeRequired) ?? false
            self.shortcodePresent = try container.decodeIfPresent(Bool.self, forKey: .shortcodePresent) ?? false
            self.blockPresent = try container.decodeIfPresent(Bool.self, forKey: .blockPresent) ?? false
            self.blockRequired = try container.decodeIfPresent(Bool.self, forKey: .blockRequired) ?? false
        }

        enum CodingKeys: String, CodingKey {
            case pageName = "page_name"
            case pageID = "page_id"
            case pageSet = "page_set"
            case pageExists = "page_exists"
            case pageVisible = "page_visible"
            case shortcode, block
            case shortcodeRequired = "shortcode_required"
            case shortcodePresent = "shortcode_present"
            case blockPresent = "block_present"
            case blockRequired = "block_required"
        }
    }
}
