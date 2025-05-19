import Foundation


/// Defines the supported WordPress API Versions.
///
enum WordPressAPIVersion: String, CaseIterable {

    /// WordPress.com Endpoint Mark 1.1
    ///
    case mark1_1 = "rest/v1.1/"

    /// WordPress.com Endpoint Mark 1.2
    ///
    case mark1_2 = "rest/v1.2/"

    /// WordPress.com Endpoint Mark 1.3
    ///
    case mark1_3 = "rest/v1.3/"

    /// WordPress.com Endpoint Mark 1.5
    ///
    case mark1_5 = "rest/v1.5/"

    /// WPcom REST API Endpoint Mark 2
    ///
    case wpcomMark2 = "wpcom/v2/"

    /// WP REST API Endpoint Mark 2
    ///
    case wpMark2 = "wp/v2/"

    /// Returns the path for the current API Version
    ///
    var path: String {
        return rawValue
    }

    /// Returns `true` if it is a WordPress.org endpoint
    ///
    /// Returns `false` if it is a WordPress.com endpoint
    ///
    var isWPOrgEndpoint: Bool {
        switch self {
        case .wpMark2:
            return true
        case .mark1_1, .mark1_2, .mark1_3, .mark1_5, .wpcomMark2:
            return false
        }
    }
}
