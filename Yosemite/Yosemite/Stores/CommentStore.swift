import Foundation
import Networking
import Storage

// MARK: - CommentStore
//
public class CommentStore: Store {
    private let remote: CommentRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = CommentRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: CommentAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? CommentAction else {
            assertionFailure("CommentStore received an unsupported action")
            return
        }

        switch action {
        case .updateApprovalStatus(let siteID, let commentID, let isApproved, let onCompletion):
            updateApprovalStatus(siteID: siteID, commentID: commentID, isApproved: isApproved, onCompletion: onCompletion)
        case .updateSpamStatus(let siteID, let commentID, let isSpam, let onCompletion):
            updateSpamStatus(siteID: siteID, commentID: commentID, isSpam: isSpam, onCompletion: onCompletion)
        case .updateTrashStatus(let siteID, let commentID, let isTrash, let onCompletion):
            updateTrashStatus(siteID: siteID, commentID: commentID, isTrash: isTrash, onCompletion: onCompletion)
        case .replyToComment(let siteID, let commentID, let productID, let content, let onCompletion):
            replyToComment(siteID: siteID, commentID: commentID, productID: productID, content: content, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension CommentStore {

    /// Updates the comment's approval status
    ///
    func updateApprovalStatus(siteID: Int64, commentID: Int64, isApproved: Bool, onCompletion: @escaping (CommentStatus?, Error?) -> Void) {
        let newStatus = isApproved ? CommentStatus.approved : CommentStatus.unapproved
        moderateComment(siteID: siteID, commentID: commentID, status: newStatus, onCompletion: onCompletion)
    }

    /// Updates the comment's spam status
    ///
    func updateSpamStatus(siteID: Int64, commentID: Int64, isSpam: Bool, onCompletion: @escaping (CommentStatus?, Error?) -> Void) {
        let newStatus = isSpam ? CommentStatus.spam : CommentStatus.unspam
        moderateComment(siteID: siteID, commentID: commentID, status: newStatus, onCompletion: onCompletion)
    }

    /// Updates the comment's trash status
    ///
    func updateTrashStatus(siteID: Int64, commentID: Int64, isTrash: Bool, onCompletion: @escaping (CommentStatus?, Error?) -> Void) {
        let newStatus = isTrash ? CommentStatus.trash : CommentStatus.untrash
        moderateComment(siteID: siteID, commentID: commentID, status: newStatus, onCompletion: onCompletion)
    }

    /// Moderates a comment with the specified status.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the comment.
    ///     - commentID: Identifier of the comment to be moderated.
    ///     - status: New status to be set.
    ///     - onCompletion: Closure to be executed upon completion.
    ///
    func moderateComment(siteID: Int64, commentID: Int64, status: CommentStatus, onCompletion: @escaping (CommentStatus?, Error?) -> Void) {
        Task {
            do {
                let updatedStatus = try await remote.moderateComment(siteID: siteID, commentID: commentID, status: status)
                await MainActor.run {
                    onCompletion(updatedStatus, nil)
                }
            } catch {
                await MainActor.run {
                    onCompletion(nil, error)
                }
            }
        }
    }

    /// Creates a comment as a reply to another comment (including product reviews).
    ///
    func replyToComment(siteID: Int64, commentID: Int64, productID: Int64, content: String, onCompletion: @escaping (Result<CommentStatus, Error>) -> Void) {
        Task {
            do {
                let status = try await remote.replyToComment(siteID: siteID, commentID: commentID, productID: productID, content: content)
                await MainActor.run {
                    onCompletion(.success(status))
                }
            } catch {
                await MainActor.run {
                    onCompletion(.failure(error))
                }
            }
        }
    }
}
