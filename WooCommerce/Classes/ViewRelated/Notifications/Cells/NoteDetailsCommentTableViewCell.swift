import Foundation
import UIKit
import WordPressUI


// MARK: - NoteDetailsCommentTableViewCell
//
class NoteDetailsCommentTableViewCell: UITableViewCell {

    /// Gravatar ImageView.
    ///
    @IBOutlet private var gravatarImageView: CircularImageView!

    /// Source's Title.
    ///
    @IBOutlet private var titleLabel: UILabel!

    /// Source's Details.
    ///
    @IBOutlet private var detailsLabel: UILabel!

    /// Main Comment's TextView.
    ///
    @IBOutlet private var textView: UITextView!


    /// Title: Usually displays the Author's Name.
    ///
    var titleText: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    /// Details: Usually displays the Time Elapsed since the comment was posted.
    ///
    var detailsText: String? {
        get {
            return detailsLabel.text
        }
        set {
            detailsLabel.text = newValue
        }
    }

    /// Comment's Body.
    ///
    var commentAttributedText: NSAttributedString? {
        get {
            return textView.attributedText
        }
        set {
            textView.attributedText = newValue
        }
    }

    /// Downloads the Gravatar Image at the specified URL (if any!).
    ///
    func downloadGravatar(with url: URL?) {
        let gravatar = url.flatMap { Gravatar($0) }

        gravatarImageView.downloadGravatar(gravatar, placeholder: .gravatarPlaceholderImage, animate: true)
    }
}
