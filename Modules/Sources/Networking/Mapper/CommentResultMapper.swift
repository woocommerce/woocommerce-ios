import Foundation


/// Mapper: Comment Moderation Result
///
struct CommentResultMapper: Mapper {

    /// (Attempts) to extract the updated `status` field from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> CommentStatus {

        let dictionary = try JSONDecoder().decode([String: AnyDecodable].self, from: response)
        let status = (dictionary[Constants.statusKey]?.value as? String) ?? ""
        return CommentStatus(rawValue: status) ?? .unknown
    }
}

private extension CommentResultMapper {
    enum Constants {
        static let statusKey: String = "status"
    }
}
