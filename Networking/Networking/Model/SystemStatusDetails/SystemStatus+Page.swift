import Foundation

public extension SystemStatus {
    /// Subtype for details about a site's pages in system status.
    ///
    struct Page: Decodable {
        public let pageName, pageID: String
        public let pageSet, pageExists, pageVisible: Bool
        public let shortcode, block: String
        public let shortcodeRequired, shortcodePresent, blockPresent, blockRequired: Bool

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
