import Foundation
import UIKit


// MARK: - NoteTableViewCell
//
class NoteTableViewCell: UITableViewCell {

    /// Sidebar
    ///
    @IBOutlet private var sidebarView: UIView!

    /// Image: Icon
    ///
    @IBOutlet private var noticonLabel: UILabel!

    /// Label: Subject
    ///
    @IBOutlet private var subjectLabel: UILabel!

    /// Label: Snippet
    ///
    @IBOutlet private var snippetLabel: UILabel!


    /// Indicates if the Row should be marked as Read or not.
    ///
    var read: Bool = false {
        didSet {
            refreshColors()
        }
    }

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


// MARK: - Private
//
private extension NoteTableViewCell {

    /// Refreshes the Cell's Colors.
    ///
    func refreshColors() {
        sidebarView.backgroundColor = read ? UIColor.clear : StyleManager.wooAccent
        noticonLabel.textColor = read ? StyleManager.wooGreyMid : StyleManager.wooAccent
    }
}
