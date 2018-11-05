import Foundation
import UIKit


// MARK: - NoteTableViewCell
//
class NoteTableViewCell: UITableViewCell {

    /// Image: Icon
    ///
    @IBOutlet private var iconImageView: UIImageView!

    /// Label: Subject
    ///
    @IBOutlet private var subjectLabel: UILabel!

    /// Label: Snippet
    ///
    @IBOutlet private var snippetLabel: UILabel!


    /// Icon Image property.
    ///
    var iconImage: UIImage? {
        get {
            return iconImageView.image
        }
        set {
            iconImageView.image = newValue
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

    override func prepareForReuse() {
        iconImage = nil
        attributedSubject = nil
        attributedSnippet = nil
    }
}
