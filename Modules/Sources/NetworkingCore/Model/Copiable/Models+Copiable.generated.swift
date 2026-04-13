// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import Foundation
import struct NetworkingCore.JetpackSite

// swiftlint:disable line_length

extension NetworkingCore.Address {
    public func copy(
        firstName: CopiableProp<String> = .copy,
        lastName: CopiableProp<String> = .copy,
        company: NullableCopiableProp<String> = .copy,
        address1: CopiableProp<String> = .copy,
        address2: NullableCopiableProp<String> = .copy,
        city: CopiableProp<String> = .copy,
        state: CopiableProp<String> = .copy,
        postcode: CopiableProp<String> = .copy,
        country: CopiableProp<String> = .copy,
        phone: NullableCopiableProp<String> = .copy,
        email: NullableCopiableProp<String> = .copy
    ) -> NetworkingCore.Address {
        let firstName = firstName ?? self.firstName
        let lastName = lastName ?? self.lastName
        let company = company ?? self.company
        let address1 = address1 ?? self.address1
        let address2 = address2 ?? self.address2
        let city = city ?? self.city
        let state = state ?? self.state
        let postcode = postcode ?? self.postcode
        let country = country ?? self.country
        let phone = phone ?? self.phone
        let email = email ?? self.email

        return NetworkingCore.Address(
            firstName: firstName,
            lastName: lastName,
            company: company,
            address1: address1,
            address2: address2,
            city: city,
            state: state,
            postcode: postcode,
            country: country,
            phone: phone,
            email: email
        )
    }
}

extension NetworkingCore.MetaData {
    public func copy(
        metadataID: CopiableProp<Int64> = .copy,
        key: CopiableProp<String> = .copy,
        value: CopiableProp<MetaDataValue> = .copy
    ) -> NetworkingCore.MetaData {
        let metadataID = metadataID ?? self.metadataID
        let key = key ?? self.key
        let value = value ?? self.value

        return NetworkingCore.MetaData(
            metadataID: metadataID,
            key: key,
            value: value
        )
    }
}

extension NetworkingCore.Note {
    public func copy(
        noteID: CopiableProp<Int64> = .copy,
        hash: CopiableProp<Int64> = .copy,
        read: CopiableProp<Bool> = .copy,
        icon: NullableCopiableProp<String> = .copy,
        noticon: NullableCopiableProp<String> = .copy,
        timestamp: CopiableProp<String> = .copy,
        timestampAsDate: CopiableProp<Date> = .copy,
        kind: CopiableProp<Note.Kind> = .copy,
        subkind: NullableCopiableProp<Note.Subkind> = .copy,
        type: NullableCopiableProp<String> = .copy,
        subtype: NullableCopiableProp<String> = .copy,
        url: NullableCopiableProp<String> = .copy,
        title: NullableCopiableProp<String> = .copy,
        subjectAsData: CopiableProp<Data> = .copy,
        subject: CopiableProp<[NoteBlock]> = .copy,
        headerAsData: CopiableProp<Data> = .copy,
        header: CopiableProp<[NoteBlock]> = .copy,
        bodyAsData: CopiableProp<Data> = .copy,
        body: CopiableProp<[NoteBlock]> = .copy,
        metaAsData: CopiableProp<Data> = .copy,
        meta: CopiableProp<MetaContainer> = .copy
    ) -> NetworkingCore.Note {
        let noteID = noteID ?? self.noteID
        let hash = hash ?? self.hash
        let read = read ?? self.read
        let icon = icon ?? self.icon
        let noticon = noticon ?? self.noticon
        let timestamp = timestamp ?? self.timestamp
        let timestampAsDate = timestampAsDate ?? self.timestampAsDate
        let kind = kind ?? self.kind
        let subkind = subkind ?? self.subkind
        let type = type ?? self.type
        let subtype = subtype ?? self.subtype
        let url = url ?? self.url
        let title = title ?? self.title
        let subjectAsData = subjectAsData ?? self.subjectAsData
        let subject = subject ?? self.subject
        let headerAsData = headerAsData ?? self.headerAsData
        let header = header ?? self.header
        let bodyAsData = bodyAsData ?? self.bodyAsData
        let body = body ?? self.body
        let metaAsData = metaAsData ?? self.metaAsData
        let meta = meta ?? self.meta

        return NetworkingCore.Note(
            noteID: noteID,
            hash: hash,
            read: read,
            icon: icon,
            noticon: noticon,
            timestamp: timestamp,
            timestampAsDate: timestampAsDate,
            kind: kind,
            subkind: subkind,
            type: type,
            subtype: subtype,
            url: url,
            title: title,
            subjectAsData: subjectAsData,
            subject: subject,
            headerAsData: headerAsData,
            header: header,
            bodyAsData: bodyAsData,
            body: body,
            metaAsData: metaAsData,
            meta: meta
        )
    }
}

extension NetworkingCore.NoteBlock {
    public func copy(
        media: CopiableProp<[NoteMedia]> = .copy,
        ranges: CopiableProp<[NoteRange]> = .copy,
        text: NullableCopiableProp<String> = .copy,
        actions: CopiableProp<[String: Bool]> = .copy,
        meta: CopiableProp<MetaContainer> = .copy,
        type: NullableCopiableProp<String> = .copy
    ) -> NetworkingCore.NoteBlock {
        let media = media ?? self.media
        let ranges = ranges ?? self.ranges
        let text = text ?? self.text
        let actions = actions ?? self.actions
        let meta = meta ?? self.meta
        let type = type ?? self.type

        return NetworkingCore.NoteBlock(
            media: media,
            ranges: ranges,
            text: text,
            actions: actions,
            meta: meta,
            type: type
        )
    }
}

extension NetworkingCore.NoteRange {
    public func copy(
        kind: CopiableProp<NoteRange.Kind> = .copy,
        type: NullableCopiableProp<String> = .copy,
        range: CopiableProp<NSRange> = .copy,
        url: NullableCopiableProp<URL> = .copy,
        commentID: NullableCopiableProp<Int64> = .copy,
        postID: NullableCopiableProp<Int64> = .copy,
        siteID: NullableCopiableProp<Int64> = .copy,
        userID: NullableCopiableProp<Int64> = .copy,
        value: NullableCopiableProp<String> = .copy
    ) -> NetworkingCore.NoteRange {
        let kind = kind ?? self.kind
        let type = type ?? self.type
        let range = range ?? self.range
        let url = url ?? self.url
        let commentID = commentID ?? self.commentID
        let postID = postID ?? self.postID
        let siteID = siteID ?? self.siteID
        let userID = userID ?? self.userID
        let value = value ?? self.value

        return NetworkingCore.NoteRange(
            kind: kind,
            type: type,
            range: range,
            url: url,
            commentID: commentID,
            postID: postID,
            siteID: siteID,
            userID: userID,
            value: value
        )
    }
}

extension NetworkingCore.Order {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        orderID: CopiableProp<Int64> = .copy,
        parentID: CopiableProp<Int64> = .copy,
        customerID: CopiableProp<Int64> = .copy,
        orderKey: CopiableProp<String> = .copy,
        isEditable: CopiableProp<Bool> = .copy,
        needsPayment: CopiableProp<Bool> = .copy,
        needsProcessing: CopiableProp<Bool> = .copy,
        number: CopiableProp<String> = .copy,
        status: CopiableProp<OrderStatusEnum> = .copy,
        currency: CopiableProp<String> = .copy,
        currencySymbol: CopiableProp<String> = .copy,
        customerNote: NullableCopiableProp<String> = .copy,
        dateCreated: CopiableProp<Date> = .copy,
        dateModified: CopiableProp<Date> = .copy,
        datePaid: NullableCopiableProp<Date> = .copy,
        discountTotal: CopiableProp<String> = .copy,
        discountTax: CopiableProp<String> = .copy,
        shippingTotal: CopiableProp<String> = .copy,
        shippingTax: CopiableProp<String> = .copy,
        total: CopiableProp<String> = .copy,
        totalTax: CopiableProp<String> = .copy,
        paymentMethodID: CopiableProp<String> = .copy,
        paymentMethodTitle: CopiableProp<String> = .copy,
        paymentURL: NullableCopiableProp<URL> = .copy,
        chargeID: NullableCopiableProp<String> = .copy,
        paymentStatusMetadata: NullableCopiableProp<String> = .copy,
        fulfillmentStatus: CopiableProp<OrderFulfillmentStatus> = .copy,
        items: CopiableProp<[OrderItem]> = .copy,
        billingAddress: NullableCopiableProp<Address> = .copy,
        shippingAddress: NullableCopiableProp<Address> = .copy,
        shippingLines: CopiableProp<[ShippingLine]> = .copy,
        coupons: CopiableProp<[OrderCouponLine]> = .copy,
        refunds: CopiableProp<[OrderRefundCondensed]> = .copy,
        fees: CopiableProp<[OrderFeeLine]> = .copy,
        taxes: CopiableProp<[OrderTaxLine]> = .copy,
        customFields: CopiableProp<[MetaData]> = .copy,
        renewalSubscriptionID: NullableCopiableProp<String> = .copy,
        appliedGiftCards: CopiableProp<[OrderGiftCard]> = .copy,
        attributionInfo: NullableCopiableProp<OrderAttributionInfo> = .copy,
        shippingLabels: CopiableProp<[ShippingLabel]> = .copy,
        fulfillments: CopiableProp<[OrderFulfillment]> = .copy,
        createdVia: NullableCopiableProp<String> = .copy
    ) -> NetworkingCore.Order {
        let siteID = siteID ?? self.siteID
        let orderID = orderID ?? self.orderID
        let parentID = parentID ?? self.parentID
        let customerID = customerID ?? self.customerID
        let orderKey = orderKey ?? self.orderKey
        let isEditable = isEditable ?? self.isEditable
        let needsPayment = needsPayment ?? self.needsPayment
        let needsProcessing = needsProcessing ?? self.needsProcessing
        let number = number ?? self.number
        let status = status ?? self.status
        let currency = currency ?? self.currency
        let currencySymbol = currencySymbol ?? self.currencySymbol
        let customerNote = customerNote ?? self.customerNote
        let dateCreated = dateCreated ?? self.dateCreated
        let dateModified = dateModified ?? self.dateModified
        let datePaid = datePaid ?? self.datePaid
        let discountTotal = discountTotal ?? self.discountTotal
        let discountTax = discountTax ?? self.discountTax
        let shippingTotal = shippingTotal ?? self.shippingTotal
        let shippingTax = shippingTax ?? self.shippingTax
        let total = total ?? self.total
        let totalTax = totalTax ?? self.totalTax
        let paymentMethodID = paymentMethodID ?? self.paymentMethodID
        let paymentMethodTitle = paymentMethodTitle ?? self.paymentMethodTitle
        let paymentURL = paymentURL ?? self.paymentURL
        let chargeID = chargeID ?? self.chargeID
        let paymentStatusMetadata = paymentStatusMetadata ?? self.paymentStatusMetadata
        let fulfillmentStatus = fulfillmentStatus ?? self.fulfillmentStatus
        let items = items ?? self.items
        let billingAddress = billingAddress ?? self.billingAddress
        let shippingAddress = shippingAddress ?? self.shippingAddress
        let shippingLines = shippingLines ?? self.shippingLines
        let coupons = coupons ?? self.coupons
        let refunds = refunds ?? self.refunds
        let fees = fees ?? self.fees
        let taxes = taxes ?? self.taxes
        let customFields = customFields ?? self.customFields
        let renewalSubscriptionID = renewalSubscriptionID ?? self.renewalSubscriptionID
        let appliedGiftCards = appliedGiftCards ?? self.appliedGiftCards
        let attributionInfo = attributionInfo ?? self.attributionInfo
        let shippingLabels = shippingLabels ?? self.shippingLabels
        let fulfillments = fulfillments ?? self.fulfillments
        let createdVia = createdVia ?? self.createdVia

        return NetworkingCore.Order(
            siteID: siteID,
            orderID: orderID,
            parentID: parentID,
            customerID: customerID,
            orderKey: orderKey,
            isEditable: isEditable,
            needsPayment: needsPayment,
            needsProcessing: needsProcessing,
            number: number,
            status: status,
            currency: currency,
            currencySymbol: currencySymbol,
            customerNote: customerNote,
            dateCreated: dateCreated,
            dateModified: dateModified,
            datePaid: datePaid,
            discountTotal: discountTotal,
            discountTax: discountTax,
            shippingTotal: shippingTotal,
            shippingTax: shippingTax,
            total: total,
            totalTax: totalTax,
            paymentMethodID: paymentMethodID,
            paymentMethodTitle: paymentMethodTitle,
            paymentURL: paymentURL,
            chargeID: chargeID,
            paymentStatusMetadata: paymentStatusMetadata,
            fulfillmentStatus: fulfillmentStatus,
            items: items,
            billingAddress: billingAddress,
            shippingAddress: shippingAddress,
            shippingLines: shippingLines,
            coupons: coupons,
            refunds: refunds,
            fees: fees,
            taxes: taxes,
            customFields: customFields,
            renewalSubscriptionID: renewalSubscriptionID,
            appliedGiftCards: appliedGiftCards,
            attributionInfo: attributionInfo,
            shippingLabels: shippingLabels,
            fulfillments: fulfillments,
            createdVia: createdVia
        )
    }
}

extension NetworkingCore.OrderAttributionInfo {
    public func copy(
        sourceType: NullableCopiableProp<String> = .copy,
        campaign: NullableCopiableProp<String> = .copy,
        source: NullableCopiableProp<String> = .copy,
        medium: NullableCopiableProp<String> = .copy,
        deviceType: NullableCopiableProp<String> = .copy,
        sessionPageViews: NullableCopiableProp<String> = .copy
    ) -> NetworkingCore.OrderAttributionInfo {
        let sourceType = sourceType ?? self.sourceType
        let campaign = campaign ?? self.campaign
        let source = source ?? self.source
        let medium = medium ?? self.medium
        let deviceType = deviceType ?? self.deviceType
        let sessionPageViews = sessionPageViews ?? self.sessionPageViews

        return NetworkingCore.OrderAttributionInfo(
            sourceType: sourceType,
            campaign: campaign,
            source: source,
            medium: medium,
            deviceType: deviceType,
            sessionPageViews: sessionPageViews
        )
    }
}

extension NetworkingCore.OrderCouponLine {
    public func copy(
        couponID: CopiableProp<Int64> = .copy,
        code: CopiableProp<String> = .copy,
        discount: CopiableProp<String> = .copy,
        discountTax: CopiableProp<String> = .copy
    ) -> NetworkingCore.OrderCouponLine {
        let couponID = couponID ?? self.couponID
        let code = code ?? self.code
        let discount = discount ?? self.discount
        let discountTax = discountTax ?? self.discountTax

        return NetworkingCore.OrderCouponLine(
            couponID: couponID,
            code: code,
            discount: discount,
            discountTax: discountTax
        )
    }
}

extension NetworkingCore.OrderFeeLine {
    public func copy(
        feeID: CopiableProp<Int64> = .copy,
        name: NullableCopiableProp<String> = .copy,
        taxClass: CopiableProp<String> = .copy,
        taxStatus: CopiableProp<OrderFeeTaxStatus> = .copy,
        total: CopiableProp<String> = .copy,
        totalTax: CopiableProp<String> = .copy,
        taxes: CopiableProp<[OrderItemTax]> = .copy,
        attributes: CopiableProp<[OrderItemAttribute]> = .copy
    ) -> NetworkingCore.OrderFeeLine {
        let feeID = feeID ?? self.feeID
        let name = name ?? self.name
        let taxClass = taxClass ?? self.taxClass
        let taxStatus = taxStatus ?? self.taxStatus
        let total = total ?? self.total
        let totalTax = totalTax ?? self.totalTax
        let taxes = taxes ?? self.taxes
        let attributes = attributes ?? self.attributes

        return NetworkingCore.OrderFeeLine(
            feeID: feeID,
            name: name,
            taxClass: taxClass,
            taxStatus: taxStatus,
            total: total,
            totalTax: totalTax,
            taxes: taxes,
            attributes: attributes
        )
    }
}

extension NetworkingCore.OrderGiftCard {
    public func copy(
        giftCardID: CopiableProp<Int64> = .copy,
        code: CopiableProp<String> = .copy,
        amount: CopiableProp<Double> = .copy
    ) -> NetworkingCore.OrderGiftCard {
        let giftCardID = giftCardID ?? self.giftCardID
        let code = code ?? self.code
        let amount = amount ?? self.amount

        return NetworkingCore.OrderGiftCard(
            giftCardID: giftCardID,
            code: code,
            amount: amount
        )
    }
}

extension NetworkingCore.OrderItem {
    public func copy(
        itemID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        productID: CopiableProp<Int64> = .copy,
        variationID: CopiableProp<Int64> = .copy,
        quantity: CopiableProp<Decimal> = .copy,
        price: CopiableProp<NSDecimalNumber> = .copy,
        sku: NullableCopiableProp<String> = .copy,
        subtotal: CopiableProp<String> = .copy,
        subtotalTax: CopiableProp<String> = .copy,
        taxClass: CopiableProp<String> = .copy,
        taxes: CopiableProp<[OrderItemTax]> = .copy,
        total: CopiableProp<String> = .copy,
        totalTax: CopiableProp<String> = .copy,
        attributes: CopiableProp<[OrderItemAttribute]> = .copy,
        addOns: CopiableProp<[OrderItemProductAddOn]> = .copy,
        image: NullableCopiableProp<OrderItemProductImage> = .copy,
        parent: NullableCopiableProp<Int64> = .copy,
        bundleConfiguration: CopiableProp<[OrderItemBundleItem]> = .copy
    ) -> NetworkingCore.OrderItem {
        let itemID = itemID ?? self.itemID
        let name = name ?? self.name
        let productID = productID ?? self.productID
        let variationID = variationID ?? self.variationID
        let quantity = quantity ?? self.quantity
        let price = price ?? self.price
        let sku = sku ?? self.sku
        let subtotal = subtotal ?? self.subtotal
        let subtotalTax = subtotalTax ?? self.subtotalTax
        let taxClass = taxClass ?? self.taxClass
        let taxes = taxes ?? self.taxes
        let total = total ?? self.total
        let totalTax = totalTax ?? self.totalTax
        let attributes = attributes ?? self.attributes
        let addOns = addOns ?? self.addOns
        let image = image ?? self.image
        let parent = parent ?? self.parent
        let bundleConfiguration = bundleConfiguration ?? self.bundleConfiguration

        return NetworkingCore.OrderItem(
            itemID: itemID,
            name: name,
            productID: productID,
            variationID: variationID,
            quantity: quantity,
            price: price,
            sku: sku,
            subtotal: subtotal,
            subtotalTax: subtotalTax,
            taxClass: taxClass,
            taxes: taxes,
            total: total,
            totalTax: totalTax,
            attributes: attributes,
            addOns: addOns,
            image: image,
            parent: parent,
            bundleConfiguration: bundleConfiguration
        )
    }
}

extension NetworkingCore.OrderItemAttribute {
    public func copy(
        metaID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        value: CopiableProp<String> = .copy
    ) -> NetworkingCore.OrderItemAttribute {
        let metaID = metaID ?? self.metaID
        let name = name ?? self.name
        let value = value ?? self.value

        return NetworkingCore.OrderItemAttribute(
            metaID: metaID,
            name: name,
            value: value
        )
    }
}

extension NetworkingCore.OrderItemBundleItem {
    public func copy(
        bundledItemID: CopiableProp<Int64> = .copy,
        productID: CopiableProp<Int64> = .copy,
        quantity: CopiableProp<Decimal> = .copy,
        isOptionalAndSelected: NullableCopiableProp<Bool> = .copy,
        variationID: NullableCopiableProp<Int64> = .copy,
        variationAttributes: NullableCopiableProp<[ProductVariationAttribute]> = .copy
    ) -> NetworkingCore.OrderItemBundleItem {
        let bundledItemID = bundledItemID ?? self.bundledItemID
        let productID = productID ?? self.productID
        let quantity = quantity ?? self.quantity
        let isOptionalAndSelected = isOptionalAndSelected ?? self.isOptionalAndSelected
        let variationID = variationID ?? self.variationID
        let variationAttributes = variationAttributes ?? self.variationAttributes

        return NetworkingCore.OrderItemBundleItem(
            bundledItemID: bundledItemID,
            productID: productID,
            quantity: quantity,
            isOptionalAndSelected: isOptionalAndSelected,
            variationID: variationID,
            variationAttributes: variationAttributes
        )
    }
}

extension NetworkingCore.OrderItemProductAddOn {
    public func copy(
        addOnID: NullableCopiableProp<Int64> = .copy,
        key: CopiableProp<String> = .copy,
        value: CopiableProp<String> = .copy
    ) -> NetworkingCore.OrderItemProductAddOn {
        let addOnID = addOnID ?? self.addOnID
        let key = key ?? self.key
        let value = value ?? self.value

        return NetworkingCore.OrderItemProductAddOn(
            addOnID: addOnID,
            key: key,
            value: value
        )
    }
}

extension NetworkingCore.OrderItemRefund {
    public func copy(
        itemID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        productID: CopiableProp<Int64> = .copy,
        variationID: CopiableProp<Int64> = .copy,
        refundedItemID: NullableCopiableProp<String> = .copy,
        quantity: CopiableProp<Decimal> = .copy,
        price: CopiableProp<NSDecimalNumber> = .copy,
        sku: NullableCopiableProp<String> = .copy,
        subtotal: CopiableProp<String> = .copy,
        subtotalTax: CopiableProp<String> = .copy,
        taxClass: CopiableProp<String> = .copy,
        taxes: CopiableProp<[OrderItemTaxRefund]> = .copy,
        total: CopiableProp<String> = .copy,
        totalTax: CopiableProp<String> = .copy
    ) -> NetworkingCore.OrderItemRefund {
        let itemID = itemID ?? self.itemID
        let name = name ?? self.name
        let productID = productID ?? self.productID
        let variationID = variationID ?? self.variationID
        let refundedItemID = refundedItemID ?? self.refundedItemID
        let quantity = quantity ?? self.quantity
        let price = price ?? self.price
        let sku = sku ?? self.sku
        let subtotal = subtotal ?? self.subtotal
        let subtotalTax = subtotalTax ?? self.subtotalTax
        let taxClass = taxClass ?? self.taxClass
        let taxes = taxes ?? self.taxes
        let total = total ?? self.total
        let totalTax = totalTax ?? self.totalTax

        return NetworkingCore.OrderItemRefund(
            itemID: itemID,
            name: name,
            productID: productID,
            variationID: variationID,
            refundedItemID: refundedItemID,
            quantity: quantity,
            price: price,
            sku: sku,
            subtotal: subtotal,
            subtotalTax: subtotalTax,
            taxClass: taxClass,
            taxes: taxes,
            total: total,
            totalTax: totalTax
        )
    }
}

extension NetworkingCore.OrderStatsV4 {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        granularity: CopiableProp<StatsGranularityV4> = .copy,
        totals: CopiableProp<OrderStatsV4Totals> = .copy,
        intervals: CopiableProp<[OrderStatsV4Interval]> = .copy
    ) -> NetworkingCore.OrderStatsV4 {
        let siteID = siteID ?? self.siteID
        let granularity = granularity ?? self.granularity
        let totals = totals ?? self.totals
        let intervals = intervals ?? self.intervals

        return NetworkingCore.OrderStatsV4(
            siteID: siteID,
            granularity: granularity,
            totals: totals,
            intervals: intervals
        )
    }
}

extension NetworkingCore.OrderStatsV4Interval {
    public func copy(
        interval: CopiableProp<String> = .copy,
        dateStart: CopiableProp<String> = .copy,
        dateEnd: CopiableProp<String> = .copy,
        subtotals: CopiableProp<OrderStatsV4Totals> = .copy
    ) -> NetworkingCore.OrderStatsV4Interval {
        let interval = interval ?? self.interval
        let dateStart = dateStart ?? self.dateStart
        let dateEnd = dateEnd ?? self.dateEnd
        let subtotals = subtotals ?? self.subtotals

        return NetworkingCore.OrderStatsV4Interval(
            interval: interval,
            dateStart: dateStart,
            dateEnd: dateEnd,
            subtotals: subtotals
        )
    }
}

extension NetworkingCore.OrderStatsV4Totals {
    public func copy(
        totalOrders: CopiableProp<Int> = .copy,
        totalItemsSold: CopiableProp<Int> = .copy,
        grossRevenue: CopiableProp<Decimal> = .copy,
        netRevenue: CopiableProp<Decimal> = .copy,
        averageOrderValue: CopiableProp<Decimal> = .copy
    ) -> NetworkingCore.OrderStatsV4Totals {
        let totalOrders = totalOrders ?? self.totalOrders
        let totalItemsSold = totalItemsSold ?? self.totalItemsSold
        let grossRevenue = grossRevenue ?? self.grossRevenue
        let netRevenue = netRevenue ?? self.netRevenue
        let averageOrderValue = averageOrderValue ?? self.averageOrderValue

        return NetworkingCore.OrderStatsV4Totals(
            totalOrders: totalOrders,
            totalItemsSold: totalItemsSold,
            grossRevenue: grossRevenue,
            netRevenue: netRevenue,
            averageOrderValue: averageOrderValue
        )
    }
}

extension NetworkingCore.OrderStatus {
    public func copy(
        name: NullableCopiableProp<String> = .copy,
        siteID: CopiableProp<Int64> = .copy,
        slug: CopiableProp<String> = .copy,
        total: CopiableProp<Int> = .copy
    ) -> NetworkingCore.OrderStatus {
        let name = name ?? self.name
        let siteID = siteID ?? self.siteID
        let slug = slug ?? self.slug
        let total = total ?? self.total

        return NetworkingCore.OrderStatus(
            name: name,
            siteID: siteID,
            slug: slug,
            total: total
        )
    }
}

extension NetworkingCore.OrderTaxLine {
    public func copy(
        taxID: CopiableProp<Int64> = .copy,
        rateCode: CopiableProp<String> = .copy,
        rateID: CopiableProp<Int64> = .copy,
        label: CopiableProp<String> = .copy,
        isCompoundTaxRate: CopiableProp<Bool> = .copy,
        totalTax: CopiableProp<String> = .copy,
        totalShippingTax: CopiableProp<String> = .copy,
        ratePercent: CopiableProp<Double> = .copy,
        attributes: CopiableProp<[OrderItemAttribute]> = .copy
    ) -> NetworkingCore.OrderTaxLine {
        let taxID = taxID ?? self.taxID
        let rateCode = rateCode ?? self.rateCode
        let rateID = rateID ?? self.rateID
        let label = label ?? self.label
        let isCompoundTaxRate = isCompoundTaxRate ?? self.isCompoundTaxRate
        let totalTax = totalTax ?? self.totalTax
        let totalShippingTax = totalShippingTax ?? self.totalShippingTax
        let ratePercent = ratePercent ?? self.ratePercent
        let attributes = attributes ?? self.attributes

        return NetworkingCore.OrderTaxLine(
            taxID: taxID,
            rateCode: rateCode,
            rateID: rateID,
            label: label,
            isCompoundTaxRate: isCompoundTaxRate,
            totalTax: totalTax,
            totalShippingTax: totalShippingTax,
            ratePercent: ratePercent,
            attributes: attributes
        )
    }
}

extension NetworkingCore.ProductVariationAttribute {
    public func copy(
        id: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        option: CopiableProp<String> = .copy
    ) -> NetworkingCore.ProductVariationAttribute {
        let id = id ?? self.id
        let name = name ?? self.name
        let option = option ?? self.option

        return NetworkingCore.ProductVariationAttribute(
            id: id,
            name: name,
            option: option
        )
    }
}

extension NetworkingCore.Refund {
    public func copy(
        refundID: CopiableProp<Int64> = .copy,
        orderID: CopiableProp<Int64> = .copy,
        siteID: CopiableProp<Int64> = .copy,
        dateCreated: CopiableProp<Date> = .copy,
        amount: CopiableProp<String> = .copy,
        reason: CopiableProp<String> = .copy,
        refundedByUserID: CopiableProp<Int64> = .copy,
        isAutomated: NullableCopiableProp<Bool> = .copy,
        createAutomated: NullableCopiableProp<Bool> = .copy,
        items: CopiableProp<[OrderItemRefund]> = .copy,
        shippingLines: NullableCopiableProp<[ShippingLine]> = .copy
    ) -> NetworkingCore.Refund {
        let refundID = refundID ?? self.refundID
        let orderID = orderID ?? self.orderID
        let siteID = siteID ?? self.siteID
        let dateCreated = dateCreated ?? self.dateCreated
        let amount = amount ?? self.amount
        let reason = reason ?? self.reason
        let refundedByUserID = refundedByUserID ?? self.refundedByUserID
        let isAutomated = isAutomated ?? self.isAutomated
        let createAutomated = createAutomated ?? self.createAutomated
        let items = items ?? self.items
        let shippingLines = shippingLines ?? self.shippingLines

        return NetworkingCore.Refund(
            refundID: refundID,
            orderID: orderID,
            siteID: siteID,
            dateCreated: dateCreated,
            amount: amount,
            reason: reason,
            refundedByUserID: refundedByUserID,
            isAutomated: isAutomated,
            createAutomated: createAutomated,
            items: items,
            shippingLines: shippingLines
        )
    }
}

extension NetworkingCore.ShippingLabel {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        orderID: CopiableProp<Int64> = .copy,
        shippingLabelID: CopiableProp<Int64> = .copy,
        carrierID: CopiableProp<String> = .copy,
        shipmentID: NullableCopiableProp<String> = .copy,
        dateCreated: CopiableProp<Date> = .copy,
        packageName: CopiableProp<String> = .copy,
        rate: CopiableProp<Double> = .copy,
        currency: CopiableProp<String> = .copy,
        trackingNumber: CopiableProp<String> = .copy,
        serviceName: CopiableProp<String> = .copy,
        refundableAmount: CopiableProp<Double> = .copy,
        status: CopiableProp<ShippingLabelStatus> = .copy,
        refund: NullableCopiableProp<ShippingLabelRefund> = .copy,
        originAddress: CopiableProp<ShippingLabelAddress> = .copy,
        destinationAddress: CopiableProp<ShippingLabelAddress> = .copy,
        productIDs: CopiableProp<[Int64]> = .copy,
        productNames: CopiableProp<[String]> = .copy,
        commercialInvoiceURL: NullableCopiableProp<String> = .copy,
        usedDate: NullableCopiableProp<Date> = .copy,
        expiryDate: NullableCopiableProp<Date> = .copy,
        hazmatCategory: NullableCopiableProp<String> = .copy
    ) -> NetworkingCore.ShippingLabel {
        let siteID = siteID ?? self.siteID
        let orderID = orderID ?? self.orderID
        let shippingLabelID = shippingLabelID ?? self.shippingLabelID
        let carrierID = carrierID ?? self.carrierID
        let shipmentID = shipmentID ?? self.shipmentID
        let dateCreated = dateCreated ?? self.dateCreated
        let packageName = packageName ?? self.packageName
        let rate = rate ?? self.rate
        let currency = currency ?? self.currency
        let trackingNumber = trackingNumber ?? self.trackingNumber
        let serviceName = serviceName ?? self.serviceName
        let refundableAmount = refundableAmount ?? self.refundableAmount
        let status = status ?? self.status
        let refund = refund ?? self.refund
        let originAddress = originAddress ?? self.originAddress
        let destinationAddress = destinationAddress ?? self.destinationAddress
        let productIDs = productIDs ?? self.productIDs
        let productNames = productNames ?? self.productNames
        let commercialInvoiceURL = commercialInvoiceURL ?? self.commercialInvoiceURL
        let usedDate = usedDate ?? self.usedDate
        let expiryDate = expiryDate ?? self.expiryDate
        let hazmatCategory = hazmatCategory ?? self.hazmatCategory

        return NetworkingCore.ShippingLabel(
            siteID: siteID,
            orderID: orderID,
            shippingLabelID: shippingLabelID,
            carrierID: carrierID,
            shipmentID: shipmentID,
            dateCreated: dateCreated,
            packageName: packageName,
            rate: rate,
            currency: currency,
            trackingNumber: trackingNumber,
            serviceName: serviceName,
            refundableAmount: refundableAmount,
            status: status,
            refund: refund,
            originAddress: originAddress,
            destinationAddress: destinationAddress,
            productIDs: productIDs,
            productNames: productNames,
            commercialInvoiceURL: commercialInvoiceURL,
            usedDate: usedDate,
            expiryDate: expiryDate,
            hazmatCategory: hazmatCategory
        )
    }
}

extension NetworkingCore.ShippingLabelAddress {
    public func copy(
        company: CopiableProp<String> = .copy,
        name: CopiableProp<String> = .copy,
        phone: CopiableProp<String> = .copy,
        country: CopiableProp<String> = .copy,
        state: CopiableProp<String> = .copy,
        address1: CopiableProp<String> = .copy,
        address2: CopiableProp<String> = .copy,
        city: CopiableProp<String> = .copy,
        postcode: CopiableProp<String> = .copy
    ) -> NetworkingCore.ShippingLabelAddress {
        let company = company ?? self.company
        let name = name ?? self.name
        let phone = phone ?? self.phone
        let country = country ?? self.country
        let state = state ?? self.state
        let address1 = address1 ?? self.address1
        let address2 = address2 ?? self.address2
        let city = city ?? self.city
        let postcode = postcode ?? self.postcode

        return NetworkingCore.ShippingLabelAddress(
            company: company,
            name: name,
            phone: phone,
            country: country,
            state: state,
            address1: address1,
            address2: address2,
            city: city,
            postcode: postcode
        )
    }
}

extension NetworkingCore.ShippingLine {
    public func copy(
        shippingID: CopiableProp<Int64> = .copy,
        methodTitle: CopiableProp<String> = .copy,
        methodID: NullableCopiableProp<String> = .copy,
        total: CopiableProp<String> = .copy,
        totalTax: CopiableProp<String> = .copy,
        taxes: CopiableProp<[ShippingLineTax]> = .copy
    ) -> NetworkingCore.ShippingLine {
        let shippingID = shippingID ?? self.shippingID
        let methodTitle = methodTitle ?? self.methodTitle
        let methodID = methodID ?? self.methodID
        let total = total ?? self.total
        let totalTax = totalTax ?? self.totalTax
        let taxes = taxes ?? self.taxes

        return NetworkingCore.ShippingLine(
            shippingID: shippingID,
            methodTitle: methodTitle,
            methodID: methodID,
            total: total,
            totalTax: totalTax,
            taxes: taxes
        )
    }
}

extension NetworkingCore.Site {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        description: CopiableProp<String> = .copy,
        url: CopiableProp<String> = .copy,
        adminURL: CopiableProp<String> = .copy,
        loginURL: CopiableProp<String> = .copy,
        isSiteOwner: CopiableProp<Bool> = .copy,
        frameNonce: CopiableProp<String> = .copy,
        plan: CopiableProp<String> = .copy,
        isAIAssistantFeatureActive: CopiableProp<Bool> = .copy,
        isJetpackThePluginInstalled: CopiableProp<Bool> = .copy,
        isJetpackConnected: CopiableProp<Bool> = .copy,
        isWooCommerceActive: CopiableProp<Bool> = .copy,
        isWordPressComStore: CopiableProp<Bool> = .copy,
        jetpackConnectionActivePlugins: CopiableProp<[String]> = .copy,
        timezone: CopiableProp<String> = .copy,
        gmtOffset: CopiableProp<Double> = .copy,
        visibility: CopiableProp<SiteVisibility> = .copy,
        canBlaze: CopiableProp<Bool> = .copy,
        isAdmin: CopiableProp<Bool> = .copy,
        wasEcommerceTrial: CopiableProp<Bool> = .copy,
        hasSSOEnabled: CopiableProp<Bool> = .copy,
        applicationPasswordAvailable: CopiableProp<Bool> = .copy,
        isGarden: CopiableProp<Bool> = .copy,
        gardenName: NullableCopiableProp<String> = .copy,
        gardenPartner: NullableCopiableProp<String> = .copy
    ) -> NetworkingCore.Site {
        let siteID = siteID ?? self.siteID
        let name = name ?? self.name
        let description = description ?? self.description
        let url = url ?? self.url
        let adminURL = adminURL ?? self.adminURL
        let loginURL = loginURL ?? self.loginURL
        let isSiteOwner = isSiteOwner ?? self.isSiteOwner
        let frameNonce = frameNonce ?? self.frameNonce
        let plan = plan ?? self.plan
        let isAIAssistantFeatureActive = isAIAssistantFeatureActive ?? self.isAIAssistantFeatureActive
        let isJetpackThePluginInstalled = isJetpackThePluginInstalled ?? self.isJetpackThePluginInstalled
        let isJetpackConnected = isJetpackConnected ?? self.isJetpackConnected
        let isWooCommerceActive = isWooCommerceActive ?? self.isWooCommerceActive
        let isWordPressComStore = isWordPressComStore ?? self.isWordPressComStore
        let jetpackConnectionActivePlugins = jetpackConnectionActivePlugins ?? self.jetpackConnectionActivePlugins
        let timezone = timezone ?? self.timezone
        let gmtOffset = gmtOffset ?? self.gmtOffset
        let visibility = visibility ?? self.visibility
        let canBlaze = canBlaze ?? self.canBlaze
        let isAdmin = isAdmin ?? self.isAdmin
        let wasEcommerceTrial = wasEcommerceTrial ?? self.wasEcommerceTrial
        let hasSSOEnabled = hasSSOEnabled ?? self.hasSSOEnabled
        let applicationPasswordAvailable = applicationPasswordAvailable ?? self.applicationPasswordAvailable
        let isGarden = isGarden ?? self.isGarden
        let gardenName = gardenName ?? self.gardenName
        let gardenPartner = gardenPartner ?? self.gardenPartner

        return NetworkingCore.Site(
            siteID: siteID,
            name: name,
            description: description,
            url: url,
            adminURL: adminURL,
            loginURL: loginURL,
            isSiteOwner: isSiteOwner,
            frameNonce: frameNonce,
            plan: plan,
            isAIAssistantFeatureActive: isAIAssistantFeatureActive,
            isJetpackThePluginInstalled: isJetpackThePluginInstalled,
            isJetpackConnected: isJetpackConnected,
            isWooCommerceActive: isWooCommerceActive,
            isWordPressComStore: isWordPressComStore,
            jetpackConnectionActivePlugins: jetpackConnectionActivePlugins,
            timezone: timezone,
            gmtOffset: gmtOffset,
            visibility: visibility,
            canBlaze: canBlaze,
            isAdmin: isAdmin,
            wasEcommerceTrial: wasEcommerceTrial,
            hasSSOEnabled: hasSSOEnabled,
            applicationPasswordAvailable: applicationPasswordAvailable,
            isGarden: isGarden,
            gardenName: gardenName,
            gardenPartner: gardenPartner
        )
    }
}

extension NetworkingCore.SiteSummaryStats {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        date: CopiableProp<String> = .copy,
        period: CopiableProp<StatGranularity> = .copy,
        visitors: CopiableProp<Int> = .copy,
        views: CopiableProp<Int> = .copy
    ) -> NetworkingCore.SiteSummaryStats {
        let siteID = siteID ?? self.siteID
        let date = date ?? self.date
        let period = period ?? self.period
        let visitors = visitors ?? self.visitors
        let views = views ?? self.views

        return NetworkingCore.SiteSummaryStats(
            siteID: siteID,
            date: date,
            period: period,
            visitors: visitors,
            views: views
        )
    }
}

extension NetworkingCore.SiteVisitStats {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        date: CopiableProp<String> = .copy,
        granularity: CopiableProp<StatGranularity> = .copy,
        items: NullableCopiableProp<[SiteVisitStatsItem]> = .copy
    ) -> NetworkingCore.SiteVisitStats {
        let siteID = siteID ?? self.siteID
        let date = date ?? self.date
        let granularity = granularity ?? self.granularity
        let items = items ?? self.items

        return NetworkingCore.SiteVisitStats(
            siteID: siteID,
            date: date,
            granularity: granularity,
            items: items
        )
    }
}

extension NetworkingCore.SiteVisitStatsItem {
    public func copy(
        period: CopiableProp<String> = .copy,
        visitors: CopiableProp<Int> = .copy,
        views: CopiableProp<Int> = .copy
    ) -> NetworkingCore.SiteVisitStatsItem {
        let period = period ?? self.period
        let visitors = visitors ?? self.visitors
        let views = views ?? self.views

        return NetworkingCore.SiteVisitStatsItem(
            period: period,
            visitors: visitors,
            views: views
        )
    }
}

extension NetworkingCore.User {
    public func copy(
        localID: CopiableProp<Int64> = .copy,
        siteID: CopiableProp<Int64> = .copy,
        email: CopiableProp<String> = .copy,
        username: CopiableProp<String> = .copy,
        firstName: CopiableProp<String> = .copy,
        lastName: CopiableProp<String> = .copy,
        nickname: CopiableProp<String> = .copy,
        roles: CopiableProp<[String]> = .copy
    ) -> NetworkingCore.User {
        let localID = localID ?? self.localID
        let siteID = siteID ?? self.siteID
        let email = email ?? self.email
        let username = username ?? self.username
        let firstName = firstName ?? self.firstName
        let lastName = lastName ?? self.lastName
        let nickname = nickname ?? self.nickname
        let roles = roles ?? self.roles

        return NetworkingCore.User(
            localID: localID,
            siteID: siteID,
            email: email,
            username: username,
            firstName: firstName,
            lastName: lastName,
            nickname: nickname,
            roles: roles
        )
    }
}

// swiftlint:enable line_length
