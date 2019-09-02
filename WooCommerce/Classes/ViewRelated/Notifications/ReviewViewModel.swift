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

    lazy var snippet: NSAttributedString? = {
        guard shouldDisplayStatus else {
            return NSAttributedString(string: review.review.strippedHTML)
        }

        let accentColor = StyleManager.hightlightTextColor
        let textColor = StyleManager.defaultTextColor

        let pendingReviewLiteral = NSAttributedString(string: Strings.pendingReviews,
                                                      attributes: [NSAttributedString.Key.foregroundColor: accentColor])

        let dot = NSAttributedString(string: " ∙ ",
                                     attributes: [NSAttributedString.Key.foregroundColor: textColor])
        let reviewText = NSAttributedString(string: review.review.strippedHTML,
                                            attributes: [NSAttributedString.Key.foregroundColor: textColor])
        let returnValue = NSMutableAttributedString(attributedString: pendingReviewLiteral)
        returnValue.append(dot)
        returnValue.append(reviewText)

        return returnValue
    }()

    lazy var rating: Int = {
        return review.rating
    }()

    lazy var notIconColor: UIColor = {
        return StyleManager.wooGreyMid
    }()

    let statusLabelBackgroundColor = StyleManager.statusWarningColor

    private var shouldDisplayStatus: Bool {
        return review.status == .hold
    }

    init(review: ProductReview) {
        self.review = review
    }
}


private extension ReviewViewModel {
    enum Strings {
        static let pendingReviews = NSLocalizedString("Pending Review",
                                                      comment: "Indicates a review is pending approval. It would read { Pending Review · Content of the reiview}")
    }
}
