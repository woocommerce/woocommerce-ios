// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import Foundation
import Networking
import WooFoundation


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
        backgroundImageDarkUrl: NullableCopiableProp<URL> = .copy,
        badgeImageUrl: NullableCopiableProp<URL> = .copy,
        badgeImageDarkUrl: NullableCopiableProp<URL> = .copy,
        template: CopiableProp<JustInTimeMessageTemplate> = .copy
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
        let badgeImageUrl = badgeImageUrl ?? self.badgeImageUrl
        let badgeImageDarkUrl = badgeImageDarkUrl ?? self.badgeImageDarkUrl
        let template = template ?? self.template

        return Yosemite.JustInTimeMessage(
            siteID: siteID,
            messageID: messageID,
            featureClass: featureClass,
            title: title,
            detail: detail,
            buttonTitle: buttonTitle,
            url: url,
            backgroundImageUrl: backgroundImageUrl,
            backgroundImageDarkUrl: backgroundImageDarkUrl,
            badgeImageUrl: badgeImageUrl,
            badgeImageDarkUrl: badgeImageDarkUrl,
            template: template
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

extension Yosemite.SystemInformation {
    public func copy(
        storeID: NullableCopiableProp<String> = .copy,
        systemPlugins: CopiableProp<[Networking.SystemPlugin]> = .copy
    ) -> Yosemite.SystemInformation {
        let storeID = storeID ?? self.storeID
        let systemPlugins = systemPlugins ?? self.systemPlugins

        return Yosemite.SystemInformation(
            storeID: storeID,
            systemPlugins: systemPlugins
        )
    }
}

extension Yosemite.WooPaymentsDepositsOverviewByCurrency {
    public func copy(
        currency: CopiableProp<CurrencyCode> = .copy,
        automaticDeposits: CopiableProp<Bool> = .copy,
        depositInterval: CopiableProp<WooPaymentsDepositInterval> = .copy,
        pendingBalanceAmount: CopiableProp<NSDecimalNumber> = .copy,
        pendingDepositDays: CopiableProp<Int> = .copy,
        lastDeposit: NullableCopiableProp<WooPaymentsDepositsOverviewByCurrency.LastDeposit> = .copy,
        availableBalance: CopiableProp<NSDecimalNumber> = .copy
    ) -> Yosemite.WooPaymentsDepositsOverviewByCurrency {
        let currency = currency ?? self.currency
        let automaticDeposits = automaticDeposits ?? self.automaticDeposits
        let depositInterval = depositInterval ?? self.depositInterval
        let pendingBalanceAmount = pendingBalanceAmount ?? self.pendingBalanceAmount
        let pendingDepositDays = pendingDepositDays ?? self.pendingDepositDays
        let lastDeposit = lastDeposit ?? self.lastDeposit
        let availableBalance = availableBalance ?? self.availableBalance

        return Yosemite.WooPaymentsDepositsOverviewByCurrency(
            currency: currency,
            automaticDeposits: automaticDeposits,
            depositInterval: depositInterval,
            pendingBalanceAmount: pendingBalanceAmount,
            pendingDepositDays: pendingDepositDays,
            lastDeposit: lastDeposit,
            availableBalance: availableBalance
        )
    }
}
