import Gridicons
import UIKit

// MARK: - ProductReviewsTableViewCell
//
final class ProductReviewsTableViewCell: UITableViewCell {

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

        configureBackground()
        configureLabels()
        configureStarView()
    }
}


extension ProductReviewsTableViewCell {
    fileprivate func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    fileprivate func configureLabels() {
        reviewLabel.applyBodyStyle()
        reviewTotalsLabel.applyBodyStyle()
    }

    fileprivate func configureStarView() {
        starRatingView.starImage = Star.filledImage
        starRatingView.emptyStarImage = Star.emptyImage
    }
}


// MARK: - Constants
//
extension ProductReviewsTableViewCell {
    fileprivate enum Star {
        static let size = Double(20)

        static let filledImage = UIImage.starImage(
            size: Star.size,
            tintColor: StyleManager.grayStarColor)

        static let emptyImage = UIImage.starOutlineImage(
            size: Star.size,
            tintColor: StyleManager.grayStarColor)
    }
}
