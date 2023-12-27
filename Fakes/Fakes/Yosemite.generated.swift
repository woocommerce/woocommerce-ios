// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Yosemite
import Networking
import Hardware
import WooFoundation

extension Yosemite.JustInTimeMessage {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Yosemite.JustInTimeMessage {
        .init(
            siteID: .fake(),
            messageID: .fake(),
            featureClass: .fake(),
            title: .fake(),
            detail: .fake(),
            buttonTitle: .fake(),
            url: .fake(),
            backgroundImageUrl: .fake(),
            backgroundImageDarkUrl: .fake(),
            badgeImageUrl: .fake(),
            badgeImageDarkUrl: .fake(),
            template: .fake()
        )
    }
}
extension Yosemite.JustInTimeMessageTemplate {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Yosemite.JustInTimeMessageTemplate {
        .banner
    }
}
extension Yosemite.ProductReviewFromNoteParcel {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Yosemite.ProductReviewFromNoteParcel {
        .init(
            note: .fake(),
            review: .fake(),
            product: .fake()
        )
    }
}
extension Yosemite.SystemInformation {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Yosemite.SystemInformation {
        .init(
            storeID: .fake(),
            systemPlugins: .fake()
        )
    }
}
extension Yosemite.WooPaymentsDepositsOverviewByCurrency {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Yosemite.WooPaymentsDepositsOverviewByCurrency {
        .init(
            currency: .fake(),
            automaticDeposits: .fake(),
            depositInterval: .fake(),
            pendingBalanceAmount: .fake(),
            pendingDepositDays: .fake(),
            lastDeposit: .fake(),
            availableBalance: .fake()
        )
    }
}
