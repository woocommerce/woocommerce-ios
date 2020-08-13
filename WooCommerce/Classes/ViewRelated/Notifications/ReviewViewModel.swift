import Foundation
import Yosemite

final class ReviewViewModel {
    let showsProductTitle: Bool
    let review: ProductReview
    let product: Product?
    let notification: Note?

    let notIcon: String = "\u{f300}"

    lazy var subject: String? = {
        let subjectUnformattedWithProductTitle = NSLocalizedString(
            "%1$@ left a review on %2$@",
            comment: "Review title. Reads as {Review author} left a review on {Product}."
        )
        let subjectUnformatted = NSLocalizedString(
            "%1$@ left a review",
            comment: "Review title. Reads as {Review author} left a review"
        )

        var formattedSubject = ""
        if showsProductTitle {
            formattedSubject = String(format: subjectUnformattedWithProductTitle, reviewerName, product?.name ?? "")
        } else {
            formattedSubject = String(format: subjectUnformatted, reviewerName)
        }
        return formattedSubject
    }()

    private lazy var reviewerName: String = {
        let reviewerName = review.reviewer

        if reviewerName.isEmpty {
            return Strings.someone
        }

        return reviewerName
    }()

    lazy var snippet: NSAttributedString? = {
        guard shouldDisplayStatus else {
            return NSAttributedString(string: review.review.strippedHTML).trimNewlines()
        }

        let accentColor = UIColor.orange
        let textColor = UIColor.textSubtle

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
        return read ? .textSubtle : .accent
    }()

    lazy var read: Bool = {
        guard let note = notification else {
            return true
        }

        return note.read
    }()

    private var shouldDisplayStatus: Bool {
        return review.status == .hold
    }

    init(showProductTitle: Bool = true, review: ProductReview, product: Product?, notification: Note?) {
        self.showsProductTitle = showProductTitle
        self.review = review
        self.product = product
        self.notification = notification
    }
}


private extension ReviewViewModel {
    enum Strings {
        static let pendingReviews = NSLocalizedString("Pending Review",
                                                      comment: "Indicates a review is pending approval. It reads { Pending Review · Content of the review}")
        static let someone = NSLocalizedString("Someone",
                                               comment: "Indicates the reviewer does not have a name. It reads { Someone left a review}")
    }
}
