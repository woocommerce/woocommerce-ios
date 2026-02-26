import Foundation

/// Protocol for reading the discovered WordPress REST API root URL for a given site.
///
public protocol RESTAPIRootCaching {
    func root(for siteURL: String) -> String?
}
