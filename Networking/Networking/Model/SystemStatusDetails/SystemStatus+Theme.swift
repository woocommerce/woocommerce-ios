import Foundation

public extension SystemStatus {
    /// Details about a store's theme in its system status report.
    ///
    struct Theme: Decodable {
        let name, version, versionLatest: String
        let authorURL: String
        let isChildTheme, hasWoocommerceSupport, hasWoocommerceFile, hasOutdatedTemplates: Bool
        let overrides: [[String: String]]
        let parentName, parentVersion, parentVersionLatest, parentAuthorURL: String

        enum CodingKeys: String, CodingKey {
            case name, version
            case versionLatest = "version_latest"
            case authorURL = "author_url"
            case isChildTheme = "is_child_theme"
            case hasWoocommerceSupport = "has_woocommerce_support"
            case hasWoocommerceFile = "has_woocommerce_file"
            case hasOutdatedTemplates = "has_outdated_templates"
            case overrides
            case parentName = "parent_name"
            case parentVersion = "parent_version"
            case parentVersionLatest = "parent_version_latest"
            case parentAuthorURL = "parent_author_url"
        }
    }
}
