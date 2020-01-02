import Foundation
import Networking



// MARK: - CommentAction: Defines all of the Actions supported by the CommentStore.
//
public enum CommentAction: Action {

    /// Updates the approval status of a comment (approved/unapproved).
    /// The completion closure will return the updated comment status or error (if any).
    ///
    case updateApprovalStatus(siteID: Int64, commentID: Int64, isApproved: Bool, onCompletion: (CommentStatus?, Error?) -> Void)

    /// Updates the spam status of a comment (spam/not-spam).
    /// The completion closure will return the updated comment status or error (if any).
    ///
    case updateSpamStatus(siteID: Int64, commentID: Int64, isSpam: Bool, onCompletion: (CommentStatus?, Error?) -> Void)

    /// Updates the trash status of a comment (trash/not-trash).
    /// The completion closure will return the updated comment status or error (if any).
    ///
    case updateTrashStatus(siteID: Int64, commentID: Int64, isTrash: Bool, onCompletion: (CommentStatus?, Error?) -> Void)
}
