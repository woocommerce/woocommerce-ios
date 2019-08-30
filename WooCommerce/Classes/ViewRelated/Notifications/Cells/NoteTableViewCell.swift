import Foundation
import UIKit
import Gridicons


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

    /// Label: Status
    ///
    @IBOutlet weak var statusLabel: PaddedLabel!

    /// Custom UIView: Rating star view
    ///
    @IBOutlet private var starRatingView: RatingView!

    /// Indicates if the Row should be marked as Read or not.
    ///
    var read: Bool = false {
        didSet {
            refreshColors()
        }
    }

    /// Star rating value (if nil, star rating view will be hidden)
    ///
    private var starRating: Int? {
        didSet {
            guard let starRating = starRating else {
                starRatingView.isHidden = true
                return
            }

            starRatingView.rating = CGFloat(starRating)
            starRatingView.isHidden = false
        }
    }


    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        noticonLabel.font = UIFont.noticon(forStyle: .body, baseSize: 25.0)
        configureStarView()
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

    func configure(with viewModel: ReviewViewModel) {
        subjectLabel.text = viewModel.subject
        snippetLabel.text = viewModel.snippet
        noticonLabel.text = viewModel.notIcon
        noticonLabel.textColor = viewModel.notIconColor

        //statusLabel.isHidden = !viewModel.shouldDisplayStatus

        if viewModel.shouldDisplayStatus {
            statusLabel.text = viewModel.status
            statusLabel.backgroundColor = viewModel.statusLabelBackgroundColor
        }
        //statusLabel.backgroundColor =

        starRating = viewModel.rating
    }
}


// MARK: - Private
//
private extension NoteTableViewCell {

    /// Refreshes the Cell's Colors.
    ///
    func refreshColors() {
        sidebarView.backgroundColor = read ? UIColor.clear : StyleManager.wooAccent
    }

    func configureStarView() {
        starRatingView.starImage = Star.filledImage
        starRatingView.emptyStarImage = Star.emptyImage
        starRatingView.isHidden = (starRating == nil)
    }
}


// MARK: - Constants!
//
private extension NoteTableViewCell {

    enum Star {
        static let size = Double(13)
        static let filledImage = UIImage.starImage(size: Star.size, tintColor: StyleManager.defaultTextColor)
        static let emptyImage = UIImage.starImage(size: Star.size, tintColor: .clear)
    }
}
