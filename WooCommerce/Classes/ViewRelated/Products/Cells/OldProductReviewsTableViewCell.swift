import UIKit
import Gridicons


// MARK: - OldProductReviewsTableViewCell
// TODO: delete this cell when `ProductDetailsViewController` will be removed
//
final class OldProductReviewsTableViewCell: UITableViewCell {

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


private extension OldProductReviewsTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureLabels() {
        reviewLabel.applyBodyStyle()
        reviewTotalsLabel.applyBodyStyle()
    }

    func configureStarView() {
        starRatingView.starImage = Star.filledImage
        starRatingView.emptyStarImage = Star.emptyImage
    }
}


// MARK: - Constants
//
private extension OldProductReviewsTableViewCell {
    enum Star {
        static let size = Double(20)
        static let filledImage = UIImage.starImage(size: Star.size)
        static let emptyImage = UIImage.starOutlineImage(size: Star.size)
    }
}
