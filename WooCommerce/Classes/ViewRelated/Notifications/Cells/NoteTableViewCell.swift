import Foundation
import UIKit
import Cosmos


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

    /// UIView: container view for rating star view
    ///
    @IBOutlet private var starViewContainer: UIView!

    /// Star View for reviews
    ///
    private var starView = CosmosView()

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

    /// Star rating value (if nil, star rating view will be hidden)
    ///
    var starRating: Int? {
        didSet {
            guard let starRating = starRating else {
                starView.isHidden = true
                return
            }

            starView.rating = Double(starRating)
            starView.isHidden = false
        }
    }


    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        noticonLabel.font = UIFont.noticon(forStyle: .title1)
        setupStarView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        // Note: this is required, since the cell unhighlight mechanism will reset the new background color
        super.setSelected(selected, animated: animated)
        refreshColors()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        // Note: this is required, since the cell unhighlight mechanism will reset the new background color
        super.setHighlighted(highlighted, animated: animated)
        refreshColors()
    }

    override public func prepareForReuse() {
        starView.prepareForReuse()
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

    func setupStarView() {
        if starViewContainer.subviews.isEmpty {
            starView.translatesAutoresizingMaskIntoConstraints = false
            starViewContainer.addSubview(starView)
            starViewContainer.pinSubviewToAllEdges(starView)
        }

        starView.accessibilityLabel = NSLocalizedString("Star rating", comment: "VoiceOver accessibility label for a product review star rating ")
        starView.settings.updateOnTouch = false
        starView.settings.fillMode = .full
        starView.settings.starSize = Constants.starSize
        starView.settings.starMargin = Constants.starMargin
        starView.settings.filledColor = StyleManager.defaultTextColor
        starView.settings.filledBorderColor = StyleManager.defaultTextColor
        starView.settings.emptyColor = .clear
        starView.settings.emptyBorderColor = .clear
        starView.isHidden = (starRating == nil)
    }    
}


// MARK: - Constants!
//
private extension NoteTableViewCell {
    enum Constants {
        static let starSize   = Double(13)
        static let starMargin = Double(0)
    }
}
