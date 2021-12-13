// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import Foundation


extension ProductReviewFromNoteParcel {
    public func copy(
        note: CopiableProp<Note> = .copy,
        review: CopiableProp<ProductReview> = .copy,
        product: CopiableProp<Product> = .copy
    ) -> ProductReviewFromNoteParcel {
        let note = note ?? self.note
        let review = review ?? self.review
        let product = product ?? self.product

        return ProductReviewFromNoteParcel(
            note: note,
            review: review,
            product: product
        )
    }
}
