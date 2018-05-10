import Foundation


/// Defines the supported WordPress API Versions.
///
enum WordPressAPIVersion: String {

    /// WordPress.com Endpoint Mark 1.1
    ///
    case mark1_1 = "rest/v1.1/"

    /// Returns the path for the current API Version
    ///
    var path: String {
        return rawValue
    }
}
