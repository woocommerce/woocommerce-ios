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
