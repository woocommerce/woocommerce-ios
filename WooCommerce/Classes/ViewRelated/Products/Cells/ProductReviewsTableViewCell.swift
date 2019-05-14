import UIKit
import Gridicons


// MARK: - ProductReviewsTableViewCell
//
class ProductReviewsTableViewCell: UITableViewCell {

    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var reviewTotalsLabel: UILabel!
    @IBOutlet weak var starRatingView: RatingView!

    var starRating: Int? {
        didSet {
            guard let starRating = starRating else {
                starRatingView.isHidden = true
                return
            }

            starRatingView.rating = CGFloat(starRating)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureStarView()
    }

    func configureStarView() {
        starRatingView.starImage = Star.filledImage
        starRatingView.emptyStarImage = Star.emptyImage
    }
}


// MARK: - Constants
//
private extension ProductReviewsTableViewCell {
    enum Star {
        static let size = Double(13)
        static let filledImage = Gridicon.iconOfType(.star,
                                                     withSize: CGSize(width: Star.size, height: Star.size)
            ).imageWithTintColor(StyleManager.defaultTextColor)
        static let emptyImage = Gridicon.iconOfType(.star,
                                                    withSize: CGSize(width: Star.size, height: Star.size)
            ).imageWithTintColor(.clear)
    }
}
