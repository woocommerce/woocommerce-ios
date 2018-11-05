import Foundation
import UIKit


// MARK: - NoteTableViewCell
//
class NoteTableViewCell: UITableViewCell {

    /// Image: Icon
    ///
    @IBOutlet private var noticonLabel: UILabel!

    /// Label: Subject
    ///
    @IBOutlet private var subjectLabel: UILabel!

    /// Label: Snippet
    ///
    @IBOutlet private var snippetLabel: UILabel!


    /// Icon Image property.
    ///
    var noticon: String? {
        get {
            return noticonLabel.text
        }
        set {
            noticonLabel.text = newValue
        }
    }

    /// Attributed Subject
    ///
    var attributedSubject: NSAttributedString? {
        get {
            return subjectLabel.attributedText
        }
        set {
            subjectLabel.attributedText = newValue
        }
    }

    /// Attributed Snippet
    ///
    var attributedSnippet: NSAttributedString? {
        get {
            return snippetLabel.attributedText
        }
        set {
            snippetLabel.attributedText = newValue
        }
    }


    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        noticonLabel.font = UIFont.noticon(forStyle: .title1)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        noticon = nil
        attributedSubject = nil
        attributedSnippet = nil
    }
}
