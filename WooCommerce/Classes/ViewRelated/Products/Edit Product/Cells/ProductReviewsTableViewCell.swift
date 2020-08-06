import UIKit

final class ProductReviewsTableViewCell: UITableViewCell {

    @IBOutlet private weak var contentImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var ratingView: RatingView!
    @IBOutlet private weak var reviewsLabel: UILabel!

    private var starRating: Double? {
        didSet {
            guard let starRating = starRating else {
                ratingView.isHidden = true
                return
            }

            ratingView.rating = CGFloat(starRating)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureImageView()
        configureLabels()
        configureStarView()
    }

    func configure(image: UIImage, title: String, details: String, ratingCount: Int, averageRating: String) {
        contentImageView.image = image
        titleLabel.text = title
        reviewsLabel.text = details
        ratingView.isHidden = ratingCount == 0
        starRating = Double(averageRating)
    }
}

// MARK: - Configure
//
private extension ProductReviewsTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureImageView() {
        contentImageView.contentMode = .center
    }

    func configureLabels() {
        titleLabel.applyBodyStyle()
        titleLabel.textColor = .text

        reviewsLabel.applySubheadlineStyle()
        reviewsLabel.textColor = .textSubtle
    }

    func configureStarView() {
        ratingView.backgroundColor = .clear
        ratingView.starImage = Star.filledImage
        ratingView.emptyStarImage = Star.emptyImage
        ratingView.configureStarColors(fullStarTintColor: UIColor.ratingStarFilled, emptyStarTintColor: .textSubtle)
    }
}


// MARK: - Constants
//
private extension ProductReviewsTableViewCell {
    enum Star {
        static let size = Double(20)
        static let filledImage = UIImage.starImage(size: Star.size)
        static let emptyImage = UIImage.starOutlineImage(size: Star.size)
    }
}
