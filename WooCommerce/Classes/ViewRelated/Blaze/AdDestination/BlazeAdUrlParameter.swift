import Foundation

/// A Blaze campaign's custom URL parameter. By default a campaign can link to a product URL,
/// or to home page URL. Optionally it can also have one or more URL parameters added to the link.
struct BlazeAdURLParameter: Equatable, Hashable {
    let key: String
    let value: String
}

/// Converts a `[BlazeAdURLParameter]` into a URL query parameter string (or empty string if the array is empty).
/// Parameter string should be in a format of "key=value&key2=value2&key3=value3"
extension Array where Element == BlazeAdURLParameter {
    func convertToQueryString() -> String {
        return self.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
    }
}
