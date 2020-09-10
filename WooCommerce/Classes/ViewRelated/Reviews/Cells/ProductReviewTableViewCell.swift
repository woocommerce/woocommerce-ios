import Foundation
import UIKit
import Gridicons


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
        configureBackground()
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
private extension ProductReviewTableViewCell {

    /// Refreshes the Cell's Colors.
    ///
    func refreshColors() {
        sidebarView.backgroundColor = read ? UIColor.clear : UIColor.accent
    }

    func configureBackground() {
        applyDefaultBackgroundStyle()

        //Background when selected
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .listBackground
    }

    func configureSubjectLabel() {
        subjectLabel.applyBodyStyle()
    }

    func configureSnippetLabel() {
        snippetLabel.applySecondaryFootnoteStyle()
        snippetLabel.numberOfLines = 2
    }

    func configureNoticonLabel() {
        noticonLabel.font = UIFont.noticon(forStyle: .body, baseSize: 25.0)
    }

    func configureStarView() {
        starRatingView.starImage = Star.filledImage
        starRatingView.emptyStarImage = Star.emptyImage
        starRatingView.isHidden = (starRating == nil)
    }

    func initialiseReadStateToFalse() {
        read = false
    }
}


// MARK: - Constants!
//
private extension ProductReviewTableViewCell {

    enum Star {
        static let size = Double(13)
        static let filledImage = UIImage.starImage(size: Star.size)
        static let emptyImage = UIImage.starImage(size: Star.size).imageWithTintColor(.clear)
    }

    enum Constants {
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
