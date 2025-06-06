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

    /// Moderates a comment with the specified status.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the comment.
    ///     - commentID: Identifier of the comment to be moderated.
    ///     - status: New status to be set.
    /// - Returns: The updated comment status.
    /// - Throws: Error if the request fails.
    ///
    public func moderateComment(siteID: Int64, commentID: Int64, status: CommentStatus) async throws -> CommentStatus {
        let path = "\(Paths.sites)/" + String(siteID) + "/" + "\(Paths.comments)/" + String(commentID)
        let parameters = [
            ParameterKeys.status: status.rawValue,
            ParameterKeys.context: ParameterValues.edit
        ]
        let mapper = CommentResultMapper()
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path, parameters: parameters)
        return try await enqueue(request, mapper: mapper)
    }

    /// Reply to a comment (including product reviews)
    ///
    /// - Parameters:
    ///    - siteID: site ID which contains the comment
    ///    - commentID: ID of the comment to reply to
    ///    - productID: ID of the product that the comment is associated to
    ///    - content: the text of the comment reply
    /// - Returns: The updated comment status
    /// - Throws: Error if the request fails
    ///
    public func replyToComment(siteID: Int64,
                             commentID: Int64,
                             productID: Int64,
                             content: String) async throws -> CommentStatus {
        let path = "sites/\(siteID)/\(Paths.comments)"
        let parameters: [String: Any] = [
            ParameterKeys.content: content,
            ParameterKeys.parent: commentID,
            ParameterKeys.post: productID
        ]
        let mapper = CommentResultMapper()
        let request = try DotcomRequest(wordpressApiVersion: .wpMark2,
                                      method: .post,
                                      path: path,
                                      parameters: parameters,
                                      availableAsRESTRequest: true)
        return try await enqueue(request, mapper: mapper)
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
