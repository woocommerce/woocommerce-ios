import Foundation
import Yosemite

final class ReviewViewModel {
    let review: ProductReview
    let product: Product?

    let notIcon: String = "\u{f300}"

    lazy var subject: String? = {
        let subjectUnformatted = NSLocalizedString(
            "%1$@ left a review on %2$@",
            comment: "Review title. Reads as {Review author} left a review on {Product}."
        )

        let formattedSubject = String(format: subjectUnformatted, self.reviewerName, product?.name ?? "")

        return formattedSubject
    }()

    private lazy var reviewerName: String = {
        let reviewerName = review.reviewer

        if reviewerName.isEmpty {
            return Strings.anonymous
        }

        return reviewerName
    }()

    lazy var snippet: NSAttributedString? = {
        guard shouldDisplayStatus else {
            return NSAttributedString(string: review.review.strippedHTML).trimNewlines()
        }

        let accentColor = StyleManager.hightlightTextColor
        let textColor = StyleManager.wooGreyTextMin

        let pendingReviewLiteral = NSAttributedString(string: Strings.pendingReviews,
                                                      attributes: [.foregroundColor: accentColor])

        let dot = NSAttributedString(string: " ∙ ",
                                     attributes: [.foregroundColor: textColor])
        let reviewText = NSAttributedString(string: review.review.strippedHTML,
                                            attributes: [.foregroundColor: textColor])
        let returnValue = NSMutableAttributedString(attributedString: pendingReviewLiteral)
        returnValue.append(dot)
        returnValue.append(reviewText)

        return returnValue.trimNewlines()
    }()

    lazy var rating: Int = {
        return review.rating
    }()

    lazy var notIconColor: UIColor = {
        return StyleManager.wooGreyMid
    }()

    private var shouldDisplayStatus: Bool {
        return review.status == .hold
    }

    init(review: ProductReview, product: Product?) {
        self.review = review
        self.product = product
    }
}


private extension ReviewViewModel {
    enum Strings {
        static let pendingReviews = NSLocalizedString("Pending Review",
                                                      comment: "Indicates a review is pending approval. It reads { Pending Review · Content of the review}")
        static let anonymous = NSLocalizedString("Anonymous",
                                                      comment: "Indicates the reviewer does not have a name. It reads { Anonymous left a review}")
    }
}
