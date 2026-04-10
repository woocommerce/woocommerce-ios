import Foundation


/// Mapper: Post
///
class PostMapper: Mapper {

    /// (Attempts) to convert a dictionary into a Post entity.
    ///
    func map(response: Data) throws -> Post {
        let decoder = JSONDecoder()
        return try decoder.decode(Post.self, from: response)
    }
}
