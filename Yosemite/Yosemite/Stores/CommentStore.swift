import Foundation
import Networking


// MARK: - CommentStore
//
public class CommentStore: Store {

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
        }
    }
}


// MARK: - Services!
//
private extension CommentStore {

    /// Updates the comment's approval status
    ///
    func updateApprovalStatus(siteID: Int, commentID: Int, isApproved: Bool, onCompletion: @escaping (CommentStatus?, Error?) -> Void) {
        let newStatus = isApproved ? CommentStatus.approved : CommentStatus.unapproved
        moderateComment(siteID: siteID, commentID: commentID, status: newStatus, onCompletion: onCompletion)
    }

    /// Updates the comment's spam status
    ///
    func updateSpamStatus(siteID: Int, commentID: Int, isSpam: Bool, onCompletion: @escaping (CommentStatus?, Error?) -> Void) {
        let newStatus = isSpam ? CommentStatus.spam : CommentStatus.unspam
        moderateComment(siteID: siteID, commentID: commentID, status: newStatus, onCompletion: onCompletion)
    }

    /// Updates the comment's trash status
    ///
    func updateTrashStatus(siteID: Int, commentID: Int, isTrash: Bool, onCompletion: @escaping (CommentStatus?, Error?) -> Void) {
        let newStatus = isTrash ? CommentStatus.trash : CommentStatus.untrash
        moderateComment(siteID: siteID, commentID: commentID, status: newStatus, onCompletion: onCompletion)
    }

    func moderateComment(siteID: Int, commentID: Int, status: CommentStatus, onCompletion: @escaping (CommentStatus?, Error?) -> Void) {
        let remote = CommentRemote(network: network)

        remote.moderateComment(siteID: siteID, commentID: commentID, status: status) { (updatedStatus, error) in
            onCompletion(updatedStatus, error)
        }
    }
}
