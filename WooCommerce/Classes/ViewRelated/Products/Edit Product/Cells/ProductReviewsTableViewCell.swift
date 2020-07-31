//
//  ProductReviewsTableViewCell.swift
//  WooCommerce
//
//  Created by Paolo Musolino on 30/07/2020.
//  Copyright © 2020 Automattic. All rights reserved.
//

import UIKit

class ProductReviewsTableViewCell: UITableViewCell {

    @IBOutlet private weak var contentImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var ratingView: RatingView!
    @IBOutlet private weak var reviewsLabel: UILabel!

    var starRating: Int? {
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

}


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
        ratingView.starImage = Star.filledImage
        ratingView.emptyStarImage = Star.emptyImage
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
