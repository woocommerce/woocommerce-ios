// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import Foundation
import Networking


extension Yosemite.JustInTimeMessage {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        messageID: CopiableProp<String> = .copy,
        featureClass: CopiableProp<String> = .copy,
        title: CopiableProp<String> = .copy,
        detail: CopiableProp<String> = .copy,
        buttonTitle: CopiableProp<String> = .copy,
        url: CopiableProp<String> = .copy,
        backgroundImageUrl: NullableCopiableProp<URL> = .copy,
        backgroundImageDarkUrl: NullableCopiableProp<URL> = .copy
    ) -> Yosemite.JustInTimeMessage {
        let siteID = siteID ?? self.siteID
        let messageID = messageID ?? self.messageID
        let featureClass = featureClass ?? self.featureClass
        let title = title ?? self.title
        let detail = detail ?? self.detail
        let buttonTitle = buttonTitle ?? self.buttonTitle
        let url = url ?? self.url
        let backgroundImageUrl = backgroundImageUrl ?? self.backgroundImageUrl
        let backgroundImageDarkUrl = backgroundImageDarkUrl ?? self.backgroundImageDarkUrl

        return Yosemite.JustInTimeMessage(
            siteID: siteID,
            messageID: messageID,
            featureClass: featureClass,
            title: title,
            detail: detail,
            buttonTitle: buttonTitle,
            url: url,
            backgroundImageUrl: backgroundImageUrl,
            backgroundImageDarkUrl: backgroundImageDarkUrl
        )
    }
}

extension Yosemite.ProductReviewFromNoteParcel {
    public func copy(
        note: CopiableProp<Note> = .copy,
        review: CopiableProp<ProductReview> = .copy,
        product: CopiableProp<Product> = .copy
    ) -> Yosemite.ProductReviewFromNoteParcel {
        let note = note ?? self.note
        let review = review ?? self.review
        let product = product ?? self.product

        return Yosemite.ProductReviewFromNoteParcel(
            note: note,
            review: review,
            product: product
        )
    }
}
