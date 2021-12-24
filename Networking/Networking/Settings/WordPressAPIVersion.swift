import Foundation


/// Defines the supported WordPress API Versions.
///
enum WordPressAPIVersion: String {

    /// WordPress.com Endpoint Mark 1.1
    ///
    case mark1_1 = "rest/v1.1/"

    /// WordPress.com Endpoint Mark 1.2
    ///
    case mark1_2 = "rest/v1.2/"

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
}
