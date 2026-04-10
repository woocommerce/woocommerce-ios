import Foundation


/// Enum containing the available moderation statuses
///
public enum CommentStatus: String {

    /// Approve the comment.
    ///
    case approved

    /// Remove the comment from public view and send it to the moderation queue.
    ///
    case unapproved

    /// Mark the comment as spam.
    ///
    case spam

    /// Unmark the comment as spam. Will attempt to set it to the previous status.
    ///
    case unspam

    /// Send a comment to the trash if trashing is enabled.
    ///
    case trash

    /// Untrash a comment. Only works when the comment is in the trash.
    ///
    case untrash

    /// Unknown status. Note: this specific case is only used locally when parsing the response from the server.
    ///
    case unknown
}

/// Comment: Remote Endpoints
///
public class CommentRemote: Remote {

    /// Moderate a comment
    ///
    /// - Parameters:
    ///   - siteID: site ID which contains the comment
    ///   - commentID: ID of the comment to moderate
    ///   - status: New status for comment
    ///   - completion: callback to be executed on completion
    ///
    public func moderateComment(siteID: Int64, commentID: Int64, status: CommentStatus, completion: @escaping (CommentStatus?, Error?) -> Void) {
        let path = "\(Paths.sites)/" + String(siteID) + "/" + "\(Paths.comments)/" + String(commentID)
        let parameters = [
            ParameterKeys.status: status.rawValue,
            ParameterKeys.context: ParameterValues.edit
        ]
        let mapper = CommentResultMapper()
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path, parameters: parameters)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Reply to a comment (including product reviews)
    ///
    /// - Parameters:
    ///    - siteID: site ID which contains the comment
    ///    - commentID: ID of the comment to reply to
    ///    - productID: ID of the product that the comment is associated to
    ///    - content: the text of the comment reply
    ///    - completion: callback to be executed on completion
    ///
    public func replyToComment(siteID: Int64,
                               commentID: Int64,
                               productID: Int64,
                               content: String,
                               completion: @escaping (Result<CommentStatus, Error>) -> Void) {
        let path = "sites/\(siteID)/\(Paths.comments)"
        let parameters: [String: Any] = [
            ParameterKeys.content: content,
            ParameterKeys.parent: commentID,
            ParameterKeys.post: productID
        ]
        let mapper = CommentResultMapper()
        do {
            let request = try DotcomRequest(wordpressApiVersion: .wpMark2,
                                            method: .post,
                                            path: path,
                                            parameters: parameters,
                                            availableAsRESTRequest: true)
            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }
}


// MARK: - Constants!
//
private extension CommentRemote {
    enum Paths {
        static let sites: String        = "sites"
        static let comments: String     = "comments"
        static let commentReply: String = "replies/new"
    }

    enum ParameterKeys {
        static let status: String       = "status"
        static let context: String      = "context"
        static let content: String      = "content"
        static let parent: String       = "parent"
        static let post: String         = "post"
    }

    enum ParameterValues {
        static let edit: String       = "edit"
    }
}
