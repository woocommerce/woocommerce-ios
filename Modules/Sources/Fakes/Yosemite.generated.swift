// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Yosemite
import Networking
import Hardware
import WooFoundation

// swiftlint:disable line_length

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
extension Yosemite.POSItemIdentifier {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Yosemite.POSItemIdentifier {
        .init(
            underlyingType: .fake(),
            itemID: .fake()
        )
    }
}
extension Yosemite.POSItemIdentifier.UnderlyingType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Yosemite.POSItemIdentifier.UnderlyingType {
        .product
    }
}
extension Yosemite.POSSimpleProduct {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Yosemite.POSSimpleProduct {
        .init(
            id: .fake(),
            name: .fake(),
            formattedPrice: .fake(),
            productImageSource: .fake(),
            productID: .fake(),
            price: .fake(),
            productType: .fake(),
            bundledItems: .fake(),
            manageStock: .fake(),
            stockQuantity: .fake(),
            stockStatusKey: .fake()
        )
    }
}
extension Yosemite.POSSite {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Yosemite.POSSite {
        .init(
            siteID: .fake(),
            lastIncrementalSyncDate: .fake(),
            lastFullSyncDate: .fake()
        )
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
extension Yosemite.StoredBookingFilters {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Yosemite.StoredBookingFilters {
        .init(
            filters: .fake()
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
extension Yosemite.WooPaymentsPayoutsOverviewByCurrency {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Yosemite.WooPaymentsPayoutsOverviewByCurrency {
        .init(
            currency: .fake(),
            automaticPayouts: .fake(),
            payoutInterval: .fake(),
            pendingBalanceAmount: .fake(),
            pendingPayoutDays: .fake(),
            lastPayout: .fake(),
            availableBalance: .fake()
        )
    }
}

// swiftlint:enable line_length
