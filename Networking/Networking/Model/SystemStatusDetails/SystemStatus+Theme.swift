import Foundation

public extension SystemStatus {
    /// Details about a store's theme in its system status report.
    ///
    struct Theme: Decodable {
        public let name, version: String
        public let authorURL: String
        public let isChildTheme, hasWoocommerceSupport, hasWoocommerceFile, hasOutdatedTemplates: Bool
        public let overrides: [[String: String]]
        public let parentName, parentVersion, parentAuthorURL: String

        enum CodingKeys: String, CodingKey {
            case name, version
            case authorURL = "author_url"
            case isChildTheme = "is_child_theme"
            case hasWoocommerceSupport = "has_woocommerce_support"
            case hasWoocommerceFile = "has_woocommerce_file"
            case hasOutdatedTemplates = "has_outdated_templates"
            case overrides
            case parentName = "parent_name"
            case parentVersion = "parent_version"
            case parentAuthorURL = "parent_author_url"
        }
    }
}
