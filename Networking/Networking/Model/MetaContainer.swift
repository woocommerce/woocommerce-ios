import Foundation


// MARK: - MetaContainer: Simple API to query the "Notification Meta" Collection.
//
public struct MetaContainer {

    /// The actual Meta Payload.
    ///
    let payload: [String: AnyCodable]


    /// Returns the Meta Link associated with the specified key (if any).
    ///
    public func link(forKey key: Keys) -> String? {
        let links = container(ofType: [String: String].self, forKey: .links)
        return links?[key.rawValue]
    }

    /// Returns the Meta ID associated with the specified key (if any).
    ///
    public func identifier(forKey key: Keys) -> Int? {
        let identifiers = container(ofType: [String: Int].self, forKey: .ids)
        return identifiers?[key.rawValue]
    }

    /// Returns the Meta Container for a given key (if any).
    ///
    private func container<T>(ofType type: T.Type, forKey key: Containers) -> T? {
        return payload[key.rawValue]?.value as? T
    }
}


// MARK: - Nested Types
//
extension MetaContainer {

    /// Known Meta Containers
    ///
    public enum Containers: String {
        case ids
        case links
        case titles
    }

    /// Known Meta Keys
    ///
    public enum Keys: String {
        case comment
        case home
        case order
        case post
        case reply  = "reply_comment"
        case site
        case user
    }
}
