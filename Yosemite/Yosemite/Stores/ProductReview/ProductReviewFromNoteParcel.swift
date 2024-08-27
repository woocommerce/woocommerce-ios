import Foundation
import Codegen

/// The result from `RetrieveProductReviewFromNoteUseCase`.
///
public struct ProductReviewFromNoteParcel: GeneratedFakeable, GeneratedCopiable {
    public let note: Note
    public let review: ProductReview
    public let product: Product

    public init(note: Note, review: ProductReview, product: Product) {
        self.note = note
        self.review = review
        self.product = product
    }
}

// MARK: Equatable conformance
extension ProductReviewFromNoteParcel: Equatable {
    public static func == (lhs: ProductReviewFromNoteParcel, rhs: ProductReviewFromNoteParcel) -> Bool {
        lhs.product == rhs.product &&
        lhs.note.hash == rhs.note.hash &&
        lhs.review == rhs.review
    }
}

// MARK: Hashable conformance
extension ProductReviewFromNoteParcel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(product)
        hasher.combine(review)
        hasher.combine(note.hash)
    }
}
