// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import Foundation
import Networking


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

extension YosemiteJustInTimeMessage {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        messageID: CopiableProp<String> = .copy,
        featureClass: CopiableProp<String> = .copy,
        title: CopiableProp<String> = .copy,
        detail: CopiableProp<String> = .copy,
        buttonTitle: CopiableProp<String> = .copy,
        url: CopiableProp<String> = .copy
    ) -> YosemiteJustInTimeMessage {
        let siteID = siteID ?? self.siteID
        let messageID = messageID ?? self.messageID
        let featureClass = featureClass ?? self.featureClass
        let title = title ?? self.title
        let detail = detail ?? self.detail
        let buttonTitle = buttonTitle ?? self.buttonTitle
        let url = url ?? self.url

        return YosemiteJustInTimeMessage(
            siteID: siteID,
            messageID: messageID,
            featureClass: featureClass,
            title: title,
            detail: detail,
            buttonTitle: buttonTitle,
            url: url
        )
    }
}
