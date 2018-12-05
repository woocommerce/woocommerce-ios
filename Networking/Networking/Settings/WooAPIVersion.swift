import Foundation


/// Defines the supported Woo API Versions.
///
public enum WooAPIVersion: String {

    /// No version
    ///
    case none = ""

    /// Woo Endpoint Mark 1
    ///
    case mark1 = "wc/v1"

    /// Woo Endpoint Mark 2
    ///
    case mark2 = "wc/v2"

    /// Woo Endpoint Mark 3
    ///
    case mark3 = "wc/v3"

    /// Returns the path for the current API Version
    ///
    var path: String {
        guard self != .none else {
            return "/"
        }

        return "/" + rawValue + "/"
    }
}
