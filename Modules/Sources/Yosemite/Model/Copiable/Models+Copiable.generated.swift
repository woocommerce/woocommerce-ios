// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import Foundation
import Networking
import WooFoundation
import enum NetworkingCore.OrderStatusEnum
import struct NetworkingCore.Address
import struct NetworkingCore.MetaData
import struct NetworkingCore.Order
import struct NetworkingCore.OrderItem
import struct NetworkingCore.OrderRefundCondensed

// swiftlint:disable line_length

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

extension Yosemite.POSItemIdentifier {
    public func copy(
        underlyingType: CopiableProp<POSItemIdentifier.UnderlyingType> = .copy,
        itemID: CopiableProp<Int64> = .copy
    ) -> Yosemite.POSItemIdentifier {
        let underlyingType = underlyingType ?? self.underlyingType
        let itemID = itemID ?? self.itemID

        return Yosemite.POSItemIdentifier(
            underlyingType: underlyingType,
            itemID: itemID
        )
    }
}

extension Yosemite.POSOrder {
    public func copy(
        id: CopiableProp<Int64> = .copy,
        number: CopiableProp<String> = .copy,
        dateCreated: CopiableProp<Date> = .copy,
        status: CopiableProp<OrderStatusEnum> = .copy,
        formattedTotal: CopiableProp<String> = .copy,
        formattedSubtotal: CopiableProp<String> = .copy,
        customerEmail: NullableCopiableProp<String> = .copy,
        paymentMethodTitle: CopiableProp<String> = .copy,
        lineItems: CopiableProp<[POSOrderItem]> = .copy,
        refunds: CopiableProp<[POSOrderRefund]> = .copy,
        formattedDiscountTotal: NullableCopiableProp<String> = .copy,
        formattedTotalTax: CopiableProp<String> = .copy,
        formattedPaymentTotal: CopiableProp<String> = .copy,
        formattedNetAmount: NullableCopiableProp<String> = .copy,
        lineItemQuantitiesByProductOrVariationID: CopiableProp<[Int64: Decimal]> = .copy
    ) -> Yosemite.POSOrder {
        let id = id ?? self.id
        let number = number ?? self.number
        let dateCreated = dateCreated ?? self.dateCreated
        let status = status ?? self.status
        let formattedTotal = formattedTotal ?? self.formattedTotal
        let formattedSubtotal = formattedSubtotal ?? self.formattedSubtotal
        let customerEmail = customerEmail ?? self.customerEmail
        let paymentMethodTitle = paymentMethodTitle ?? self.paymentMethodTitle
        let lineItems = lineItems ?? self.lineItems
        let refunds = refunds ?? self.refunds
        let formattedDiscountTotal = formattedDiscountTotal ?? self.formattedDiscountTotal
        let formattedTotalTax = formattedTotalTax ?? self.formattedTotalTax
        let formattedPaymentTotal = formattedPaymentTotal ?? self.formattedPaymentTotal
        let formattedNetAmount = formattedNetAmount ?? self.formattedNetAmount
        let lineItemQuantitiesByProductOrVariationID = lineItemQuantitiesByProductOrVariationID ?? self.lineItemQuantitiesByProductOrVariationID

        return Yosemite.POSOrder(
            id: id,
            number: number,
            dateCreated: dateCreated,
            status: status,
            formattedTotal: formattedTotal,
            formattedSubtotal: formattedSubtotal,
            customerEmail: customerEmail,
            paymentMethodTitle: paymentMethodTitle,
            lineItems: lineItems,
            refunds: refunds,
            formattedDiscountTotal: formattedDiscountTotal,
            formattedTotalTax: formattedTotalTax,
            formattedPaymentTotal: formattedPaymentTotal,
            formattedNetAmount: formattedNetAmount,
            lineItemQuantitiesByProductOrVariationID: lineItemQuantitiesByProductOrVariationID
        )
    }
}

extension Yosemite.POSSimpleProduct {
    public func copy(
        id: CopiableProp<POSItemIdentifier> = .copy,
        name: CopiableProp<String> = .copy,
        formattedPrice: CopiableProp<String> = .copy,
        productImageSource: NullableCopiableProp<String> = .copy,
        productID: CopiableProp<Int64> = .copy,
        price: CopiableProp<String> = .copy,
        productType: CopiableProp<Networking.ProductType> = .copy,
        bundledItems: CopiableProp<[Networking.ProductBundleItem]> = .copy,
        manageStock: CopiableProp<Bool> = .copy,
        stockQuantity: NullableCopiableProp<Decimal> = .copy,
        stockStatusKey: CopiableProp<String> = .copy
    ) -> Yosemite.POSSimpleProduct {
        let id = id ?? self.id
        let name = name ?? self.name
        let formattedPrice = formattedPrice ?? self.formattedPrice
        let productImageSource = productImageSource ?? self.productImageSource
        let productID = productID ?? self.productID
        let price = price ?? self.price
        let productType = productType ?? self.productType
        let bundledItems = bundledItems ?? self.bundledItems
        let manageStock = manageStock ?? self.manageStock
        let stockQuantity = stockQuantity ?? self.stockQuantity
        let stockStatusKey = stockStatusKey ?? self.stockStatusKey

        return Yosemite.POSSimpleProduct(
            id: id,
            name: name,
            formattedPrice: formattedPrice,
            productImageSource: productImageSource,
            productID: productID,
            price: price,
            productType: productType,
            bundledItems: bundledItems,
            manageStock: manageStock,
            stockQuantity: stockQuantity,
            stockStatusKey: stockStatusKey
        )
    }
}

extension Yosemite.POSSite {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        lastIncrementalSyncDate: NullableCopiableProp<Date> = .copy,
        lastFullSyncDate: NullableCopiableProp<Date> = .copy
    ) -> Yosemite.POSSite {
        let siteID = siteID ?? self.siteID
        let lastIncrementalSyncDate = lastIncrementalSyncDate ?? self.lastIncrementalSyncDate
        let lastFullSyncDate = lastFullSyncDate ?? self.lastFullSyncDate

        return Yosemite.POSSite(
            siteID: siteID,
            lastIncrementalSyncDate: lastIncrementalSyncDate,
            lastFullSyncDate: lastFullSyncDate
        )
    }
}

extension Yosemite.ProductReviewFromNoteParcel {
    public func copy(
        note: NullableCopiableProp<Note> = .copy,
        review: CopiableProp<ProductReview> = .copy,
        product: CopiableProp<Networking.Product> = .copy
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

extension Yosemite.WooPaymentsPayoutsOverviewByCurrency {
    public func copy(
        currency: CopiableProp<CurrencyCode> = .copy,
        automaticPayouts: CopiableProp<Bool> = .copy,
        payoutInterval: CopiableProp<WooPaymentsPayoutInterval> = .copy,
        pendingBalanceAmount: CopiableProp<NSDecimalNumber> = .copy,
        pendingPayoutDays: CopiableProp<Int> = .copy,
        lastPayout: NullableCopiableProp<WooPaymentsPayoutsOverviewByCurrency.LastPayout> = .copy,
        availableBalance: CopiableProp<NSDecimalNumber> = .copy
    ) -> Yosemite.WooPaymentsPayoutsOverviewByCurrency {
        let currency = currency ?? self.currency
        let automaticPayouts = automaticPayouts ?? self.automaticPayouts
        let payoutInterval = payoutInterval ?? self.payoutInterval
        let pendingBalanceAmount = pendingBalanceAmount ?? self.pendingBalanceAmount
        let pendingPayoutDays = pendingPayoutDays ?? self.pendingPayoutDays
        let lastPayout = lastPayout ?? self.lastPayout
        let availableBalance = availableBalance ?? self.availableBalance

        return Yosemite.WooPaymentsPayoutsOverviewByCurrency(
            currency: currency,
            automaticPayouts: automaticPayouts,
            payoutInterval: payoutInterval,
            pendingBalanceAmount: pendingBalanceAmount,
            pendingPayoutDays: pendingPayoutDays,
            lastPayout: lastPayout,
            availableBalance: availableBalance
        )
    }
}

// swiftlint:enable line_length
