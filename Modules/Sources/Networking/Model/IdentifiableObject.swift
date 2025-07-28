import Foundation

/// Represents any entity with an ID.
///
/// This type can be used to extract the ID from any entity, regardless of whether it is otherwise well formed.
///
struct IdentifiableObject: Decodable, Identifiable {

    /// Object identifier
    ///
    public let id: Int64
}
