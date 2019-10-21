import Foundation
import Gridicons
import UIKit

// MARK: - ProductReviewTableViewCell
//
final class ProductReviewTableViewCell: UITableViewCell {

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
        configureSubjectLabel()
        configureSnippetLabel()
        configureNoticonLabel()
        configureStarView()

        initialiseReadStateToFalse()
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


    // MARK: - Public API

    func configure(with viewModel: ReviewViewModel) {
        subjectLabel.text = viewModel.subject
        snippetLabel.attributedText = viewModel.snippet
        noticonLabel.text = viewModel.notIcon
        noticonLabel.textColor = viewModel.notIconColor

        read = viewModel.read

        starRating = viewModel.rating
    }
}


// MARK: - Private
//
extension ProductReviewTableViewCell {

    /// Refreshes the Cell's Colors.
    ///
    fileprivate func refreshColors() {
        sidebarView.backgroundColor = read ? UIColor.clear : StyleManager.wooAccent
    }

    fileprivate func configureSubjectLabel() {
        subjectLabel.applyBodyStyle()
    }

    fileprivate func configureSnippetLabel() {
        snippetLabel.applySecondaryFootnoteStyle()
        snippetLabel.numberOfLines = 2
    }

    fileprivate func configureNoticonLabel() {
        noticonLabel.font = UIFont.noticon(forStyle: .body, baseSize: 25.0)
    }

    fileprivate func configureStarView() {
        starRatingView.starImage = Star.filledImage
        starRatingView.emptyStarImage = Star.emptyImage
        starRatingView.isHidden = (starRating == nil)
    }

    fileprivate func initialiseReadStateToFalse() {
        read = false
    }
}


// MARK: - Constants!
//
extension ProductReviewTableViewCell {

    fileprivate enum Star {
        static let size = Double(13)
        static let filledImage = UIImage.starImage(size: Star.size, tintColor: StyleManager.yellowStarColor)
        static let emptyImage = UIImage.starImage(size: Star.size, tintColor: .clear)
    }

    fileprivate enum Constants {
        static let cornerRadius = CGFloat(2.0)
    }
}


// MARK: - Tests
extension ProductReviewTableViewCell {
    func getNotIconLabel() -> UILabel {
        return noticonLabel
    }

    func getSubjectLabel() -> UILabel {
        return subjectLabel
    }

    func getSnippetLabel() -> UILabel {
        return snippetLabel
    }

    func getStarRatingView() -> RatingView {
        return starRatingView
    }
}
