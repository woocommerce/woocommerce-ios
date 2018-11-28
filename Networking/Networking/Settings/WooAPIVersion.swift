import Foundation


/// Defines the supported Woo API Versions.
///
enum WooAPIVersion: String {

    /// No version specificed (root path)
    ///
    case none = "/"

    /// Woo Endpoint Mark 2
    ///
    case mark2 = "/wc/v2/"

    /// Returns the path for the current API Version
    ///
    var path: String {
        return rawValue
    }
}
