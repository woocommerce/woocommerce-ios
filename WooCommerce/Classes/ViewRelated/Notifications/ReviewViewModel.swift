import Foundation
import Yosemite

final class ReviewViewModel {
    private let review: ProductReview

    let notIcon: String = "\u{f300}"

    lazy var subject: String? = {
        let subjectUnformatted = NSLocalizedString(
            "%@ left a review on %@",
            comment: "Review title. Reads as {Review author} left a review on {Product}."
        )

        let formattedSubject = String(format: subjectUnformatted, review.reviewer, "a product")

        return formattedSubject
    }()

    lazy var snippet: String? = {
        return review.review.strippedHTML
    }()

    lazy var rating: Int = {
        return review.rating
    }()

    lazy var notIconColor: UIColor = {
        return StyleManager.wooGreyMid
    }()

    init(review: ProductReview) {
        self.review = review
    }
}
