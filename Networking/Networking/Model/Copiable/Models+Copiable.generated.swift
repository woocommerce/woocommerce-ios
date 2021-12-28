// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import Foundation


extension AddOnGroup {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        groupID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        priority: CopiableProp<Int64> = .copy,
        addOns: CopiableProp<[ProductAddOn]> = .copy
    ) -> AddOnGroup {
        let siteID = siteID ?? self.siteID
        let groupID = groupID ?? self.groupID
        let name = name ?? self.name
        let priority = priority ?? self.priority
        let addOns = addOns ?? self.addOns

        return AddOnGroup(
            siteID: siteID,
            groupID: groupID,
            name: name,
            priority: priority,
            addOns: addOns
        )
    }
}

extension Address {
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
    ) -> Address {
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

        return Address(
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

extension Coupon {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        couponID: CopiableProp<Int64> = .copy,
        code: CopiableProp<String> = .copy,
        amount: CopiableProp<String> = .copy,
        dateCreated: CopiableProp<Date> = .copy,
        dateModified: CopiableProp<Date> = .copy,
        discountType: CopiableProp<Coupon.DiscountType> = .copy,
        description: CopiableProp<String> = .copy,
        dateExpires: NullableCopiableProp<Date> = .copy,
        usageCount: CopiableProp<Int64> = .copy,
        individualUse: CopiableProp<Bool> = .copy,
        productIds: CopiableProp<[Int64]> = .copy,
        excludedProductIds: CopiableProp<[Int64]> = .copy,
        usageLimit: NullableCopiableProp<Int64> = .copy,
        usageLimitPerUser: NullableCopiableProp<Int64> = .copy,
        limitUsageToXItems: NullableCopiableProp<Int64> = .copy,
        freeShipping: CopiableProp<Bool> = .copy,
        productCategories: CopiableProp<[Int64]> = .copy,
        excludedProductCategories: CopiableProp<[Int64]> = .copy,
        excludeSaleItems: CopiableProp<Bool> = .copy,
        minimumAmount: CopiableProp<String> = .copy,
        maximumAmount: CopiableProp<String> = .copy,
        emailRestrictions: CopiableProp<[String]> = .copy,
        usedBy: CopiableProp<[String]> = .copy
    ) -> Coupon {
        let siteID = siteID ?? self.siteID
        let couponID = couponID ?? self.couponID
        let code = code ?? self.code
        let amount = amount ?? self.amount
        let dateCreated = dateCreated ?? self.dateCreated
        let dateModified = dateModified ?? self.dateModified
        let discountType = discountType ?? self.discountType
        let description = description ?? self.description
        let dateExpires = dateExpires ?? self.dateExpires
        let usageCount = usageCount ?? self.usageCount
        let individualUse = individualUse ?? self.individualUse
        let productIds = productIds ?? self.productIds
        let excludedProductIds = excludedProductIds ?? self.excludedProductIds
        let usageLimit = usageLimit ?? self.usageLimit
        let usageLimitPerUser = usageLimitPerUser ?? self.usageLimitPerUser
        let limitUsageToXItems = limitUsageToXItems ?? self.limitUsageToXItems
        let freeShipping = freeShipping ?? self.freeShipping
        let productCategories = productCategories ?? self.productCategories
        let excludedProductCategories = excludedProductCategories ?? self.excludedProductCategories
        let excludeSaleItems = excludeSaleItems ?? self.excludeSaleItems
        let minimumAmount = minimumAmount ?? self.minimumAmount
        let maximumAmount = maximumAmount ?? self.maximumAmount
        let emailRestrictions = emailRestrictions ?? self.emailRestrictions
        let usedBy = usedBy ?? self.usedBy

        return Coupon(
            siteID: siteID,
            couponID: couponID,
            code: code,
            amount: amount,
            dateCreated: dateCreated,
            dateModified: dateModified,
            discountType: discountType,
            description: description,
            dateExpires: dateExpires,
            usageCount: usageCount,
            individualUse: individualUse,
            productIds: productIds,
            excludedProductIds: excludedProductIds,
            usageLimit: usageLimit,
            usageLimitPerUser: usageLimitPerUser,
            limitUsageToXItems: limitUsageToXItems,
            freeShipping: freeShipping,
            productCategories: productCategories,
            excludedProductCategories: excludedProductCategories,
            excludeSaleItems: excludeSaleItems,
            minimumAmount: minimumAmount,
            maximumAmount: maximumAmount,
            emailRestrictions: emailRestrictions,
            usedBy: usedBy
        )
    }
}

extension Order {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        orderID: CopiableProp<Int64> = .copy,
        parentID: CopiableProp<Int64> = .copy,
        customerID: CopiableProp<Int64> = .copy,
        orderKey: CopiableProp<String> = .copy,
        number: CopiableProp<String> = .copy,
        status: CopiableProp<OrderStatusEnum> = .copy,
        currency: CopiableProp<String> = .copy,
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
        items: CopiableProp<[OrderItem]> = .copy,
        billingAddress: NullableCopiableProp<Address> = .copy,
        shippingAddress: NullableCopiableProp<Address> = .copy,
        shippingLines: CopiableProp<[ShippingLine]> = .copy,
        coupons: CopiableProp<[OrderCouponLine]> = .copy,
        refunds: CopiableProp<[OrderRefundCondensed]> = .copy,
        fees: CopiableProp<[OrderFeeLine]> = .copy
    ) -> Order {
        let siteID = siteID ?? self.siteID
        let orderID = orderID ?? self.orderID
        let parentID = parentID ?? self.parentID
        let customerID = customerID ?? self.customerID
        let orderKey = orderKey ?? self.orderKey
        let number = number ?? self.number
        let status = status ?? self.status
        let currency = currency ?? self.currency
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
        let items = items ?? self.items
        let billingAddress = billingAddress ?? self.billingAddress
        let shippingAddress = shippingAddress ?? self.shippingAddress
        let shippingLines = shippingLines ?? self.shippingLines
        let coupons = coupons ?? self.coupons
        let refunds = refunds ?? self.refunds
        let fees = fees ?? self.fees

        return Order(
            siteID: siteID,
            orderID: orderID,
            parentID: parentID,
            customerID: customerID,
            orderKey: orderKey,
            number: number,
            status: status,
            currency: currency,
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
            items: items,
            billingAddress: billingAddress,
            shippingAddress: shippingAddress,
            shippingLines: shippingLines,
            coupons: coupons,
            refunds: refunds,
            fees: fees
        )
    }
}

extension OrderFeeLine {
    public func copy(
        feeID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        taxClass: CopiableProp<String> = .copy,
        taxStatus: CopiableProp<OrderFeeTaxStatus> = .copy,
        total: CopiableProp<String> = .copy,
        totalTax: CopiableProp<String> = .copy,
        taxes: CopiableProp<[OrderItemTax]> = .copy,
        attributes: CopiableProp<[OrderItemAttribute]> = .copy
    ) -> OrderFeeLine {
        let feeID = feeID ?? self.feeID
        let name = name ?? self.name
        let taxClass = taxClass ?? self.taxClass
        let taxStatus = taxStatus ?? self.taxStatus
        let total = total ?? self.total
        let totalTax = totalTax ?? self.totalTax
        let taxes = taxes ?? self.taxes
        let attributes = attributes ?? self.attributes

        return OrderFeeLine(
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

extension OrderItem {
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
        attributes: CopiableProp<[OrderItemAttribute]> = .copy
    ) -> OrderItem {
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

        return OrderItem(
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
            attributes: attributes
        )
    }
}

extension OrderItemAttribute {
    public func copy(
        metaID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        value: CopiableProp<String> = .copy
    ) -> OrderItemAttribute {
        let metaID = metaID ?? self.metaID
        let name = name ?? self.name
        let value = value ?? self.value

        return OrderItemAttribute(
            metaID: metaID,
            name: name,
            value: value
        )
    }
}

extension OrderItemRefund {
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
        taxes: CopiableProp<[OrderItemTaxRefund]> = .copy,
        total: CopiableProp<String> = .copy,
        totalTax: CopiableProp<String> = .copy
    ) -> OrderItemRefund {
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

        return OrderItemRefund(
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
            totalTax: totalTax
        )
    }
}

extension PaymentGatewayAccount {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        gatewayID: CopiableProp<String> = .copy,
        status: CopiableProp<String> = .copy,
        hasPendingRequirements: CopiableProp<Bool> = .copy,
        hasOverdueRequirements: CopiableProp<Bool> = .copy,
        currentDeadline: NullableCopiableProp<Date> = .copy,
        statementDescriptor: CopiableProp<String> = .copy,
        defaultCurrency: CopiableProp<String> = .copy,
        supportedCurrencies: CopiableProp<[String]> = .copy,
        country: CopiableProp<String> = .copy,
        isCardPresentEligible: CopiableProp<Bool> = .copy,
        isLive: CopiableProp<Bool> = .copy,
        isInTestMode: CopiableProp<Bool> = .copy
    ) -> PaymentGatewayAccount {
        let siteID = siteID ?? self.siteID
        let gatewayID = gatewayID ?? self.gatewayID
        let status = status ?? self.status
        let hasPendingRequirements = hasPendingRequirements ?? self.hasPendingRequirements
        let hasOverdueRequirements = hasOverdueRequirements ?? self.hasOverdueRequirements
        let currentDeadline = currentDeadline ?? self.currentDeadline
        let statementDescriptor = statementDescriptor ?? self.statementDescriptor
        let defaultCurrency = defaultCurrency ?? self.defaultCurrency
        let supportedCurrencies = supportedCurrencies ?? self.supportedCurrencies
        let country = country ?? self.country
        let isCardPresentEligible = isCardPresentEligible ?? self.isCardPresentEligible
        let isLive = isLive ?? self.isLive
        let isInTestMode = isInTestMode ?? self.isInTestMode

        return PaymentGatewayAccount(
            siteID: siteID,
            gatewayID: gatewayID,
            status: status,
            hasPendingRequirements: hasPendingRequirements,
            hasOverdueRequirements: hasOverdueRequirements,
            currentDeadline: currentDeadline,
            statementDescriptor: statementDescriptor,
            defaultCurrency: defaultCurrency,
            supportedCurrencies: supportedCurrencies,
            country: country,
            isCardPresentEligible: isCardPresentEligible,
            isLive: isLive,
            isInTestMode: isInTestMode
        )
    }
}

extension Product {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        productID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        slug: CopiableProp<String> = .copy,
        permalink: CopiableProp<String> = .copy,
        date: CopiableProp<Date> = .copy,
        dateCreated: CopiableProp<Date> = .copy,
        dateModified: NullableCopiableProp<Date> = .copy,
        dateOnSaleStart: NullableCopiableProp<Date> = .copy,
        dateOnSaleEnd: NullableCopiableProp<Date> = .copy,
        productTypeKey: CopiableProp<String> = .copy,
        statusKey: CopiableProp<String> = .copy,
        featured: CopiableProp<Bool> = .copy,
        catalogVisibilityKey: CopiableProp<String> = .copy,
        fullDescription: NullableCopiableProp<String> = .copy,
        shortDescription: NullableCopiableProp<String> = .copy,
        sku: NullableCopiableProp<String> = .copy,
        price: CopiableProp<String> = .copy,
        regularPrice: NullableCopiableProp<String> = .copy,
        salePrice: NullableCopiableProp<String> = .copy,
        onSale: CopiableProp<Bool> = .copy,
        purchasable: CopiableProp<Bool> = .copy,
        totalSales: CopiableProp<Int> = .copy,
        virtual: CopiableProp<Bool> = .copy,
        downloadable: CopiableProp<Bool> = .copy,
        downloads: CopiableProp<[ProductDownload]> = .copy,
        downloadLimit: CopiableProp<Int64> = .copy,
        downloadExpiry: CopiableProp<Int64> = .copy,
        buttonText: CopiableProp<String> = .copy,
        externalURL: NullableCopiableProp<String> = .copy,
        taxStatusKey: CopiableProp<String> = .copy,
        taxClass: NullableCopiableProp<String> = .copy,
        manageStock: CopiableProp<Bool> = .copy,
        stockQuantity: NullableCopiableProp<Decimal> = .copy,
        stockStatusKey: CopiableProp<String> = .copy,
        backordersKey: CopiableProp<String> = .copy,
        backordersAllowed: CopiableProp<Bool> = .copy,
        backordered: CopiableProp<Bool> = .copy,
        soldIndividually: CopiableProp<Bool> = .copy,
        weight: NullableCopiableProp<String> = .copy,
        dimensions: CopiableProp<ProductDimensions> = .copy,
        shippingRequired: CopiableProp<Bool> = .copy,
        shippingTaxable: CopiableProp<Bool> = .copy,
        shippingClass: NullableCopiableProp<String> = .copy,
        shippingClassID: CopiableProp<Int64> = .copy,
        productShippingClass: NullableCopiableProp<ProductShippingClass> = .copy,
        reviewsAllowed: CopiableProp<Bool> = .copy,
        averageRating: CopiableProp<String> = .copy,
        ratingCount: CopiableProp<Int> = .copy,
        relatedIDs: CopiableProp<[Int64]> = .copy,
        upsellIDs: CopiableProp<[Int64]> = .copy,
        crossSellIDs: CopiableProp<[Int64]> = .copy,
        parentID: CopiableProp<Int64> = .copy,
        purchaseNote: NullableCopiableProp<String> = .copy,
        categories: CopiableProp<[ProductCategory]> = .copy,
        tags: CopiableProp<[ProductTag]> = .copy,
        images: CopiableProp<[ProductImage]> = .copy,
        attributes: CopiableProp<[ProductAttribute]> = .copy,
        defaultAttributes: CopiableProp<[ProductDefaultAttribute]> = .copy,
        variations: CopiableProp<[Int64]> = .copy,
        groupedProducts: CopiableProp<[Int64]> = .copy,
        menuOrder: CopiableProp<Int> = .copy,
        addOns: CopiableProp<[ProductAddOn]> = .copy
    ) -> Product {
        let siteID = siteID ?? self.siteID
        let productID = productID ?? self.productID
        let name = name ?? self.name
        let slug = slug ?? self.slug
        let permalink = permalink ?? self.permalink
        let date = date ?? self.date
        let dateCreated = dateCreated ?? self.dateCreated
        let dateModified = dateModified ?? self.dateModified
        let dateOnSaleStart = dateOnSaleStart ?? self.dateOnSaleStart
        let dateOnSaleEnd = dateOnSaleEnd ?? self.dateOnSaleEnd
        let productTypeKey = productTypeKey ?? self.productTypeKey
        let statusKey = statusKey ?? self.statusKey
        let featured = featured ?? self.featured
        let catalogVisibilityKey = catalogVisibilityKey ?? self.catalogVisibilityKey
        let fullDescription = fullDescription ?? self.fullDescription
        let shortDescription = shortDescription ?? self.shortDescription
        let sku = sku ?? self.sku
        let price = price ?? self.price
        let regularPrice = regularPrice ?? self.regularPrice
        let salePrice = salePrice ?? self.salePrice
        let onSale = onSale ?? self.onSale
        let purchasable = purchasable ?? self.purchasable
        let totalSales = totalSales ?? self.totalSales
        let virtual = virtual ?? self.virtual
        let downloadable = downloadable ?? self.downloadable
        let downloads = downloads ?? self.downloads
        let downloadLimit = downloadLimit ?? self.downloadLimit
        let downloadExpiry = downloadExpiry ?? self.downloadExpiry
        let buttonText = buttonText ?? self.buttonText
        let externalURL = externalURL ?? self.externalURL
        let taxStatusKey = taxStatusKey ?? self.taxStatusKey
        let taxClass = taxClass ?? self.taxClass
        let manageStock = manageStock ?? self.manageStock
        let stockQuantity = stockQuantity ?? self.stockQuantity
        let stockStatusKey = stockStatusKey ?? self.stockStatusKey
        let backordersKey = backordersKey ?? self.backordersKey
        let backordersAllowed = backordersAllowed ?? self.backordersAllowed
        let backordered = backordered ?? self.backordered
        let soldIndividually = soldIndividually ?? self.soldIndividually
        let weight = weight ?? self.weight
        let dimensions = dimensions ?? self.dimensions
        let shippingRequired = shippingRequired ?? self.shippingRequired
        let shippingTaxable = shippingTaxable ?? self.shippingTaxable
        let shippingClass = shippingClass ?? self.shippingClass
        let shippingClassID = shippingClassID ?? self.shippingClassID
        let productShippingClass = productShippingClass ?? self.productShippingClass
        let reviewsAllowed = reviewsAllowed ?? self.reviewsAllowed
        let averageRating = averageRating ?? self.averageRating
        let ratingCount = ratingCount ?? self.ratingCount
        let relatedIDs = relatedIDs ?? self.relatedIDs
        let upsellIDs = upsellIDs ?? self.upsellIDs
        let crossSellIDs = crossSellIDs ?? self.crossSellIDs
        let parentID = parentID ?? self.parentID
        let purchaseNote = purchaseNote ?? self.purchaseNote
        let categories = categories ?? self.categories
        let tags = tags ?? self.tags
        let images = images ?? self.images
        let attributes = attributes ?? self.attributes
        let defaultAttributes = defaultAttributes ?? self.defaultAttributes
        let variations = variations ?? self.variations
        let groupedProducts = groupedProducts ?? self.groupedProducts
        let menuOrder = menuOrder ?? self.menuOrder
        let addOns = addOns ?? self.addOns

        return Product(
            siteID: siteID,
            productID: productID,
            name: name,
            slug: slug,
            permalink: permalink,
            date: date,
            dateCreated: dateCreated,
            dateModified: dateModified,
            dateOnSaleStart: dateOnSaleStart,
            dateOnSaleEnd: dateOnSaleEnd,
            productTypeKey: productTypeKey,
            statusKey: statusKey,
            featured: featured,
            catalogVisibilityKey: catalogVisibilityKey,
            fullDescription: fullDescription,
            shortDescription: shortDescription,
            sku: sku,
            price: price,
            regularPrice: regularPrice,
            salePrice: salePrice,
            onSale: onSale,
            purchasable: purchasable,
            totalSales: totalSales,
            virtual: virtual,
            downloadable: downloadable,
            downloads: downloads,
            downloadLimit: downloadLimit,
            downloadExpiry: downloadExpiry,
            buttonText: buttonText,
            externalURL: externalURL,
            taxStatusKey: taxStatusKey,
            taxClass: taxClass,
            manageStock: manageStock,
            stockQuantity: stockQuantity,
            stockStatusKey: stockStatusKey,
            backordersKey: backordersKey,
            backordersAllowed: backordersAllowed,
            backordered: backordered,
            soldIndividually: soldIndividually,
            weight: weight,
            dimensions: dimensions,
            shippingRequired: shippingRequired,
            shippingTaxable: shippingTaxable,
            shippingClass: shippingClass,
            shippingClassID: shippingClassID,
            productShippingClass: productShippingClass,
            reviewsAllowed: reviewsAllowed,
            averageRating: averageRating,
            ratingCount: ratingCount,
            relatedIDs: relatedIDs,
            upsellIDs: upsellIDs,
            crossSellIDs: crossSellIDs,
            parentID: parentID,
            purchaseNote: purchaseNote,
            categories: categories,
            tags: tags,
            images: images,
            attributes: attributes,
            defaultAttributes: defaultAttributes,
            variations: variations,
            groupedProducts: groupedProducts,
            menuOrder: menuOrder,
            addOns: addOns
        )
    }
}

extension ProductAddOn {
    public func copy(
        type: CopiableProp<AddOnType> = .copy,
        display: CopiableProp<AddOnDisplay> = .copy,
        name: CopiableProp<String> = .copy,
        titleFormat: CopiableProp<AddOnTitleFormat> = .copy,
        descriptionEnabled: CopiableProp<Int> = .copy,
        description: CopiableProp<String> = .copy,
        required: CopiableProp<Int> = .copy,
        position: CopiableProp<Int> = .copy,
        restrictions: CopiableProp<Int> = .copy,
        restrictionsType: CopiableProp<AddOnRestrictionsType> = .copy,
        adjustPrice: CopiableProp<Int> = .copy,
        priceType: CopiableProp<AddOnPriceType> = .copy,
        price: CopiableProp<String> = .copy,
        min: CopiableProp<Int> = .copy,
        max: CopiableProp<Int> = .copy,
        options: CopiableProp<[ProductAddOnOption]> = .copy
    ) -> ProductAddOn {
        let type = type ?? self.type
        let display = display ?? self.display
        let name = name ?? self.name
        let titleFormat = titleFormat ?? self.titleFormat
        let descriptionEnabled = descriptionEnabled ?? self.descriptionEnabled
        let description = description ?? self.description
        let required = required ?? self.required
        let position = position ?? self.position
        let restrictions = restrictions ?? self.restrictions
        let restrictionsType = restrictionsType ?? self.restrictionsType
        let adjustPrice = adjustPrice ?? self.adjustPrice
        let priceType = priceType ?? self.priceType
        let price = price ?? self.price
        let min = min ?? self.min
        let max = max ?? self.max
        let options = options ?? self.options

        return ProductAddOn(
            type: type,
            display: display,
            name: name,
            titleFormat: titleFormat,
            descriptionEnabled: descriptionEnabled,
            description: description,
            required: required,
            position: position,
            restrictions: restrictions,
            restrictionsType: restrictionsType,
            adjustPrice: adjustPrice,
            priceType: priceType,
            price: price,
            min: min,
            max: max,
            options: options
        )
    }
}

extension ProductAddOnOption {
    public func copy(
        label: NullableCopiableProp<String> = .copy,
        price: NullableCopiableProp<String> = .copy,
        priceType: NullableCopiableProp<AddOnPriceType> = .copy,
        imageID: NullableCopiableProp<String> = .copy
    ) -> ProductAddOnOption {
        let label = label ?? self.label
        let price = price ?? self.price
        let priceType = priceType ?? self.priceType
        let imageID = imageID ?? self.imageID

        return ProductAddOnOption(
            label: label,
            price: price,
            priceType: priceType,
            imageID: imageID
        )
    }
}

extension ProductAttribute {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        attributeID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        position: CopiableProp<Int> = .copy,
        visible: CopiableProp<Bool> = .copy,
        variation: CopiableProp<Bool> = .copy,
        options: CopiableProp<[String]> = .copy
    ) -> ProductAttribute {
        let siteID = siteID ?? self.siteID
        let attributeID = attributeID ?? self.attributeID
        let name = name ?? self.name
        let position = position ?? self.position
        let visible = visible ?? self.visible
        let variation = variation ?? self.variation
        let options = options ?? self.options

        return ProductAttribute(
            siteID: siteID,
            attributeID: attributeID,
            name: name,
            position: position,
            visible: visible,
            variation: variation,
            options: options
        )
    }
}

extension ProductImage {
    public func copy(
        imageID: CopiableProp<Int64> = .copy,
        dateCreated: CopiableProp<Date> = .copy,
        dateModified: NullableCopiableProp<Date> = .copy,
        src: CopiableProp<String> = .copy,
        name: NullableCopiableProp<String> = .copy,
        alt: NullableCopiableProp<String> = .copy
    ) -> ProductImage {
        let imageID = imageID ?? self.imageID
        let dateCreated = dateCreated ?? self.dateCreated
        let dateModified = dateModified ?? self.dateModified
        let src = src ?? self.src
        let name = name ?? self.name
        let alt = alt ?? self.alt

        return ProductImage(
            imageID: imageID,
            dateCreated: dateCreated,
            dateModified: dateModified,
            src: src,
            name: name,
            alt: alt
        )
    }
}

extension ProductVariation {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        productID: CopiableProp<Int64> = .copy,
        productVariationID: CopiableProp<Int64> = .copy,
        attributes: CopiableProp<[ProductVariationAttribute]> = .copy,
        image: NullableCopiableProp<ProductImage> = .copy,
        permalink: CopiableProp<String> = .copy,
        dateCreated: CopiableProp<Date> = .copy,
        dateModified: NullableCopiableProp<Date> = .copy,
        dateOnSaleStart: NullableCopiableProp<Date> = .copy,
        dateOnSaleEnd: NullableCopiableProp<Date> = .copy,
        status: CopiableProp<ProductStatus> = .copy,
        description: NullableCopiableProp<String> = .copy,
        sku: NullableCopiableProp<String> = .copy,
        price: CopiableProp<String> = .copy,
        regularPrice: NullableCopiableProp<String> = .copy,
        salePrice: NullableCopiableProp<String> = .copy,
        onSale: CopiableProp<Bool> = .copy,
        purchasable: CopiableProp<Bool> = .copy,
        virtual: CopiableProp<Bool> = .copy,
        downloadable: CopiableProp<Bool> = .copy,
        downloads: CopiableProp<[ProductDownload]> = .copy,
        downloadLimit: CopiableProp<Int64> = .copy,
        downloadExpiry: CopiableProp<Int64> = .copy,
        taxStatusKey: CopiableProp<String> = .copy,
        taxClass: NullableCopiableProp<String> = .copy,
        manageStock: CopiableProp<Bool> = .copy,
        stockQuantity: NullableCopiableProp<Decimal> = .copy,
        stockStatus: CopiableProp<ProductStockStatus> = .copy,
        backordersKey: CopiableProp<String> = .copy,
        backordersAllowed: CopiableProp<Bool> = .copy,
        backordered: CopiableProp<Bool> = .copy,
        weight: NullableCopiableProp<String> = .copy,
        dimensions: CopiableProp<ProductDimensions> = .copy,
        shippingClass: NullableCopiableProp<String> = .copy,
        shippingClassID: CopiableProp<Int64> = .copy,
        menuOrder: CopiableProp<Int64> = .copy
    ) -> ProductVariation {
        let siteID = siteID ?? self.siteID
        let productID = productID ?? self.productID
        let productVariationID = productVariationID ?? self.productVariationID
        let attributes = attributes ?? self.attributes
        let image = image ?? self.image
        let permalink = permalink ?? self.permalink
        let dateCreated = dateCreated ?? self.dateCreated
        let dateModified = dateModified ?? self.dateModified
        let dateOnSaleStart = dateOnSaleStart ?? self.dateOnSaleStart
        let dateOnSaleEnd = dateOnSaleEnd ?? self.dateOnSaleEnd
        let status = status ?? self.status
        let description = description ?? self.description
        let sku = sku ?? self.sku
        let price = price ?? self.price
        let regularPrice = regularPrice ?? self.regularPrice
        let salePrice = salePrice ?? self.salePrice
        let onSale = onSale ?? self.onSale
        let purchasable = purchasable ?? self.purchasable
        let virtual = virtual ?? self.virtual
        let downloadable = downloadable ?? self.downloadable
        let downloads = downloads ?? self.downloads
        let downloadLimit = downloadLimit ?? self.downloadLimit
        let downloadExpiry = downloadExpiry ?? self.downloadExpiry
        let taxStatusKey = taxStatusKey ?? self.taxStatusKey
        let taxClass = taxClass ?? self.taxClass
        let manageStock = manageStock ?? self.manageStock
        let stockQuantity = stockQuantity ?? self.stockQuantity
        let stockStatus = stockStatus ?? self.stockStatus
        let backordersKey = backordersKey ?? self.backordersKey
        let backordersAllowed = backordersAllowed ?? self.backordersAllowed
        let backordered = backordered ?? self.backordered
        let weight = weight ?? self.weight
        let dimensions = dimensions ?? self.dimensions
        let shippingClass = shippingClass ?? self.shippingClass
        let shippingClassID = shippingClassID ?? self.shippingClassID
        let menuOrder = menuOrder ?? self.menuOrder

        return ProductVariation(
            siteID: siteID,
            productID: productID,
            productVariationID: productVariationID,
            attributes: attributes,
            image: image,
            permalink: permalink,
            dateCreated: dateCreated,
            dateModified: dateModified,
            dateOnSaleStart: dateOnSaleStart,
            dateOnSaleEnd: dateOnSaleEnd,
            status: status,
            description: description,
            sku: sku,
            price: price,
            regularPrice: regularPrice,
            salePrice: salePrice,
            onSale: onSale,
            purchasable: purchasable,
            virtual: virtual,
            downloadable: downloadable,
            downloads: downloads,
            downloadLimit: downloadLimit,
            downloadExpiry: downloadExpiry,
            taxStatusKey: taxStatusKey,
            taxClass: taxClass,
            manageStock: manageStock,
            stockQuantity: stockQuantity,
            stockStatus: stockStatus,
            backordersKey: backordersKey,
            backordersAllowed: backordersAllowed,
            backordered: backordered,
            weight: weight,
            dimensions: dimensions,
            shippingClass: shippingClass,
            shippingClassID: shippingClassID,
            menuOrder: menuOrder
        )
    }
}

extension Refund {
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
    ) -> Refund {
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

        return Refund(
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

extension ShipmentTracking {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        orderID: CopiableProp<Int64> = .copy,
        trackingID: CopiableProp<String> = .copy,
        trackingNumber: CopiableProp<String> = .copy,
        trackingProvider: NullableCopiableProp<String> = .copy,
        trackingURL: NullableCopiableProp<String> = .copy,
        dateShipped: NullableCopiableProp<Date> = .copy
    ) -> ShipmentTracking {
        let siteID = siteID ?? self.siteID
        let orderID = orderID ?? self.orderID
        let trackingID = trackingID ?? self.trackingID
        let trackingNumber = trackingNumber ?? self.trackingNumber
        let trackingProvider = trackingProvider ?? self.trackingProvider
        let trackingURL = trackingURL ?? self.trackingURL
        let dateShipped = dateShipped ?? self.dateShipped

        return ShipmentTracking(
            siteID: siteID,
            orderID: orderID,
            trackingID: trackingID,
            trackingNumber: trackingNumber,
            trackingProvider: trackingProvider,
            trackingURL: trackingURL,
            dateShipped: dateShipped
        )
    }
}

extension ShippingLabel {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        orderID: CopiableProp<Int64> = .copy,
        shippingLabelID: CopiableProp<Int64> = .copy,
        carrierID: CopiableProp<String> = .copy,
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
        commercialInvoiceURL: NullableCopiableProp<String> = .copy
    ) -> ShippingLabel {
        let siteID = siteID ?? self.siteID
        let orderID = orderID ?? self.orderID
        let shippingLabelID = shippingLabelID ?? self.shippingLabelID
        let carrierID = carrierID ?? self.carrierID
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

        return ShippingLabel(
            siteID: siteID,
            orderID: orderID,
            shippingLabelID: shippingLabelID,
            carrierID: carrierID,
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
            commercialInvoiceURL: commercialInvoiceURL
        )
    }
}

extension ShippingLabelAccountSettings {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        canManagePayments: CopiableProp<Bool> = .copy,
        canEditSettings: CopiableProp<Bool> = .copy,
        storeOwnerDisplayName: CopiableProp<String> = .copy,
        storeOwnerUsername: CopiableProp<String> = .copy,
        storeOwnerWpcomUsername: CopiableProp<String> = .copy,
        storeOwnerWpcomEmail: CopiableProp<String> = .copy,
        paymentMethods: CopiableProp<[ShippingLabelPaymentMethod]> = .copy,
        selectedPaymentMethodID: CopiableProp<Int64> = .copy,
        isEmailReceiptsEnabled: CopiableProp<Bool> = .copy,
        paperSize: CopiableProp<ShippingLabelPaperSize> = .copy,
        lastSelectedPackageID: CopiableProp<String> = .copy
    ) -> ShippingLabelAccountSettings {
        let siteID = siteID ?? self.siteID
        let canManagePayments = canManagePayments ?? self.canManagePayments
        let canEditSettings = canEditSettings ?? self.canEditSettings
        let storeOwnerDisplayName = storeOwnerDisplayName ?? self.storeOwnerDisplayName
        let storeOwnerUsername = storeOwnerUsername ?? self.storeOwnerUsername
        let storeOwnerWpcomUsername = storeOwnerWpcomUsername ?? self.storeOwnerWpcomUsername
        let storeOwnerWpcomEmail = storeOwnerWpcomEmail ?? self.storeOwnerWpcomEmail
        let paymentMethods = paymentMethods ?? self.paymentMethods
        let selectedPaymentMethodID = selectedPaymentMethodID ?? self.selectedPaymentMethodID
        let isEmailReceiptsEnabled = isEmailReceiptsEnabled ?? self.isEmailReceiptsEnabled
        let paperSize = paperSize ?? self.paperSize
        let lastSelectedPackageID = lastSelectedPackageID ?? self.lastSelectedPackageID

        return ShippingLabelAccountSettings(
            siteID: siteID,
            canManagePayments: canManagePayments,
            canEditSettings: canEditSettings,
            storeOwnerDisplayName: storeOwnerDisplayName,
            storeOwnerUsername: storeOwnerUsername,
            storeOwnerWpcomUsername: storeOwnerWpcomUsername,
            storeOwnerWpcomEmail: storeOwnerWpcomEmail,
            paymentMethods: paymentMethods,
            selectedPaymentMethodID: selectedPaymentMethodID,
            isEmailReceiptsEnabled: isEmailReceiptsEnabled,
            paperSize: paperSize,
            lastSelectedPackageID: lastSelectedPackageID
        )
    }
}

extension ShippingLabelAddress {
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
    ) -> ShippingLabelAddress {
        let company = company ?? self.company
        let name = name ?? self.name
        let phone = phone ?? self.phone
        let country = country ?? self.country
        let state = state ?? self.state
        let address1 = address1 ?? self.address1
        let address2 = address2 ?? self.address2
        let city = city ?? self.city
        let postcode = postcode ?? self.postcode

        return ShippingLabelAddress(
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

extension ShippingLabelCustomsForm {
    public func copy(
        packageID: CopiableProp<String> = .copy,
        packageName: CopiableProp<String> = .copy,
        contentsType: CopiableProp<ShippingLabelCustomsForm.ContentsType> = .copy,
        contentExplanation: CopiableProp<String> = .copy,
        restrictionType: CopiableProp<ShippingLabelCustomsForm.RestrictionType> = .copy,
        restrictionComments: CopiableProp<String> = .copy,
        nonDeliveryOption: CopiableProp<ShippingLabelCustomsForm.NonDeliveryOption> = .copy,
        itn: CopiableProp<String> = .copy,
        items: CopiableProp<[ShippingLabelCustomsForm.Item]> = .copy
    ) -> ShippingLabelCustomsForm {
        let packageID = packageID ?? self.packageID
        let packageName = packageName ?? self.packageName
        let contentsType = contentsType ?? self.contentsType
        let contentExplanation = contentExplanation ?? self.contentExplanation
        let restrictionType = restrictionType ?? self.restrictionType
        let restrictionComments = restrictionComments ?? self.restrictionComments
        let nonDeliveryOption = nonDeliveryOption ?? self.nonDeliveryOption
        let itn = itn ?? self.itn
        let items = items ?? self.items

        return ShippingLabelCustomsForm(
            packageID: packageID,
            packageName: packageName,
            contentsType: contentsType,
            contentExplanation: contentExplanation,
            restrictionType: restrictionType,
            restrictionComments: restrictionComments,
            nonDeliveryOption: nonDeliveryOption,
            itn: itn,
            items: items
        )
    }
}

extension ShippingLabelCustomsForm.Item {
    public func copy(
        description: CopiableProp<String> = .copy,
        quantity: CopiableProp<Decimal> = .copy,
        value: CopiableProp<Double> = .copy,
        weight: CopiableProp<Double> = .copy,
        hsTariffNumber: CopiableProp<String> = .copy,
        originCountry: CopiableProp<String> = .copy,
        productID: CopiableProp<Int64> = .copy
    ) -> ShippingLabelCustomsForm.Item {
        let description = description ?? self.description
        let quantity = quantity ?? self.quantity
        let value = value ?? self.value
        let weight = weight ?? self.weight
        let hsTariffNumber = hsTariffNumber ?? self.hsTariffNumber
        let originCountry = originCountry ?? self.originCountry
        let productID = productID ?? self.productID

        return ShippingLabelCustomsForm.Item(
            description: description,
            quantity: quantity,
            value: value,
            weight: weight,
            hsTariffNumber: hsTariffNumber,
            originCountry: originCountry,
            productID: productID
        )
    }
}

extension ShippingLabelPackagesResponse {
    public func copy(
        storeOptions: CopiableProp<ShippingLabelStoreOptions> = .copy,
        customPackages: CopiableProp<[ShippingLabelCustomPackage]> = .copy,
        predefinedOptions: CopiableProp<[ShippingLabelPredefinedOption]> = .copy,
        unactivatedPredefinedOptions: CopiableProp<[ShippingLabelPredefinedOption]> = .copy
    ) -> ShippingLabelPackagesResponse {
        let storeOptions = storeOptions ?? self.storeOptions
        let customPackages = customPackages ?? self.customPackages
        let predefinedOptions = predefinedOptions ?? self.predefinedOptions
        let unactivatedPredefinedOptions = unactivatedPredefinedOptions ?? self.unactivatedPredefinedOptions

        return ShippingLabelPackagesResponse(
            storeOptions: storeOptions,
            customPackages: customPackages,
            predefinedOptions: predefinedOptions,
            unactivatedPredefinedOptions: unactivatedPredefinedOptions
        )
    }
}

extension ShippingLabelPaymentMethod {
    public func copy(
        paymentMethodID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        cardType: CopiableProp<ShippingLabelPaymentCardType> = .copy,
        cardDigits: CopiableProp<String> = .copy,
        expiry: NullableCopiableProp<Date> = .copy
    ) -> ShippingLabelPaymentMethod {
        let paymentMethodID = paymentMethodID ?? self.paymentMethodID
        let name = name ?? self.name
        let cardType = cardType ?? self.cardType
        let cardDigits = cardDigits ?? self.cardDigits
        let expiry = expiry ?? self.expiry

        return ShippingLabelPaymentMethod(
            paymentMethodID: paymentMethodID,
            name: name,
            cardType: cardType,
            cardDigits: cardDigits,
            expiry: expiry
        )
    }
}

extension ShippingLabelPurchase {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        orderID: CopiableProp<Int64> = .copy,
        shippingLabelID: CopiableProp<Int64> = .copy,
        carrierID: NullableCopiableProp<String> = .copy,
        dateCreated: CopiableProp<Date> = .copy,
        packageName: CopiableProp<String> = .copy,
        trackingNumber: NullableCopiableProp<String> = .copy,
        serviceName: CopiableProp<String> = .copy,
        refundableAmount: CopiableProp<Double> = .copy,
        status: CopiableProp<ShippingLabelStatus> = .copy,
        productIDs: CopiableProp<[Int64]> = .copy,
        productNames: CopiableProp<[String]> = .copy
    ) -> ShippingLabelPurchase {
        let siteID = siteID ?? self.siteID
        let orderID = orderID ?? self.orderID
        let shippingLabelID = shippingLabelID ?? self.shippingLabelID
        let carrierID = carrierID ?? self.carrierID
        let dateCreated = dateCreated ?? self.dateCreated
        let packageName = packageName ?? self.packageName
        let trackingNumber = trackingNumber ?? self.trackingNumber
        let serviceName = serviceName ?? self.serviceName
        let refundableAmount = refundableAmount ?? self.refundableAmount
        let status = status ?? self.status
        let productIDs = productIDs ?? self.productIDs
        let productNames = productNames ?? self.productNames

        return ShippingLabelPurchase(
            siteID: siteID,
            orderID: orderID,
            shippingLabelID: shippingLabelID,
            carrierID: carrierID,
            dateCreated: dateCreated,
            packageName: packageName,
            trackingNumber: trackingNumber,
            serviceName: serviceName,
            refundableAmount: refundableAmount,
            status: status,
            productIDs: productIDs,
            productNames: productNames
        )
    }
}

extension Site {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        name: CopiableProp<String> = .copy,
        description: CopiableProp<String> = .copy,
        url: CopiableProp<String> = .copy,
        adminURL: CopiableProp<String> = .copy,
        plan: CopiableProp<String> = .copy,
        isJetpackThePluginInstalled: CopiableProp<Bool> = .copy,
        isJetpackConnected: CopiableProp<Bool> = .copy,
        isWooCommerceActive: CopiableProp<Bool> = .copy,
        isWordPressStore: CopiableProp<Bool> = .copy,
        jetpackConnectionActivePlugins: CopiableProp<[String]> = .copy,
        timezone: CopiableProp<String> = .copy,
        gmtOffset: CopiableProp<Double> = .copy
    ) -> Site {
        let siteID = siteID ?? self.siteID
        let name = name ?? self.name
        let description = description ?? self.description
        let url = url ?? self.url
        let adminURL = adminURL ?? self.adminURL
        let plan = plan ?? self.plan
        let isJetpackThePluginInstalled = isJetpackThePluginInstalled ?? self.isJetpackThePluginInstalled
        let isJetpackConnected = isJetpackConnected ?? self.isJetpackConnected
        let isWooCommerceActive = isWooCommerceActive ?? self.isWooCommerceActive
        let isWordPressStore = isWordPressStore ?? self.isWordPressStore
        let jetpackConnectionActivePlugins = jetpackConnectionActivePlugins ?? self.jetpackConnectionActivePlugins
        let timezone = timezone ?? self.timezone
        let gmtOffset = gmtOffset ?? self.gmtOffset

        return Site(
            siteID: siteID,
            name: name,
            description: description,
            url: url,
            adminURL: adminURL,
            plan: plan,
            isJetpackThePluginInstalled: isJetpackThePluginInstalled,
            isJetpackConnected: isJetpackConnected,
            isWooCommerceActive: isWooCommerceActive,
            isWordPressStore: isWordPressStore,
            jetpackConnectionActivePlugins: jetpackConnectionActivePlugins,
            timezone: timezone,
            gmtOffset: gmtOffset
        )
    }
}

extension SitePlugin {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        plugin: CopiableProp<String> = .copy,
        status: CopiableProp<SitePluginStatusEnum> = .copy,
        name: CopiableProp<String> = .copy,
        pluginUri: CopiableProp<String> = .copy,
        author: CopiableProp<String> = .copy,
        authorUri: CopiableProp<String> = .copy,
        descriptionRaw: CopiableProp<String> = .copy,
        descriptionRendered: CopiableProp<String> = .copy,
        version: CopiableProp<String> = .copy,
        networkOnly: CopiableProp<Bool> = .copy,
        requiresWPVersion: CopiableProp<String> = .copy,
        requiresPHPVersion: CopiableProp<String> = .copy,
        textDomain: CopiableProp<String> = .copy
    ) -> SitePlugin {
        let siteID = siteID ?? self.siteID
        let plugin = plugin ?? self.plugin
        let status = status ?? self.status
        let name = name ?? self.name
        let pluginUri = pluginUri ?? self.pluginUri
        let author = author ?? self.author
        let authorUri = authorUri ?? self.authorUri
        let descriptionRaw = descriptionRaw ?? self.descriptionRaw
        let descriptionRendered = descriptionRendered ?? self.descriptionRendered
        let version = version ?? self.version
        let networkOnly = networkOnly ?? self.networkOnly
        let requiresWPVersion = requiresWPVersion ?? self.requiresWPVersion
        let requiresPHPVersion = requiresPHPVersion ?? self.requiresPHPVersion
        let textDomain = textDomain ?? self.textDomain

        return SitePlugin(
            siteID: siteID,
            plugin: plugin,
            status: status,
            name: name,
            pluginUri: pluginUri,
            author: author,
            authorUri: authorUri,
            descriptionRaw: descriptionRaw,
            descriptionRendered: descriptionRendered,
            version: version,
            networkOnly: networkOnly,
            requiresWPVersion: requiresWPVersion,
            requiresPHPVersion: requiresPHPVersion,
            textDomain: textDomain
        )
    }
}

extension SiteSetting {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        settingID: CopiableProp<String> = .copy,
        label: CopiableProp<String> = .copy,
        settingDescription: CopiableProp<String> = .copy,
        value: CopiableProp<String> = .copy,
        settingGroupKey: CopiableProp<String> = .copy
    ) -> SiteSetting {
        let siteID = siteID ?? self.siteID
        let settingID = settingID ?? self.settingID
        let label = label ?? self.label
        let settingDescription = settingDescription ?? self.settingDescription
        let value = value ?? self.value
        let settingGroupKey = settingGroupKey ?? self.settingGroupKey

        return SiteSetting(
            siteID: siteID,
            settingID: settingID,
            label: label,
            settingDescription: settingDescription,
            value: value,
            settingGroupKey: settingGroupKey
        )
    }
}

extension SystemPlugin {
    public func copy(
        siteID: CopiableProp<Int64> = .copy,
        plugin: CopiableProp<String> = .copy,
        name: CopiableProp<String> = .copy,
        version: CopiableProp<String> = .copy,
        versionLatest: CopiableProp<String> = .copy,
        url: CopiableProp<String> = .copy,
        authorName: CopiableProp<String> = .copy,
        authorUrl: CopiableProp<String> = .copy,
        networkActivated: CopiableProp<Bool> = .copy,
        active: CopiableProp<Bool> = .copy
    ) -> SystemPlugin {
        let siteID = siteID ?? self.siteID
        let plugin = plugin ?? self.plugin
        let name = name ?? self.name
        let version = version ?? self.version
        let versionLatest = versionLatest ?? self.versionLatest
        let url = url ?? self.url
        let authorName = authorName ?? self.authorName
        let authorUrl = authorUrl ?? self.authorUrl
        let networkActivated = networkActivated ?? self.networkActivated
        let active = active ?? self.active

        return SystemPlugin(
            siteID: siteID,
            plugin: plugin,
            name: name,
            version: version,
            versionLatest: versionLatest,
            url: url,
            authorName: authorName,
            authorUrl: authorUrl,
            networkActivated: networkActivated,
            active: active
        )
    }
}

extension WordPressMedia {
    public func copy(
        mediaID: CopiableProp<Int64> = .copy,
        date: CopiableProp<Date> = .copy,
        slug: CopiableProp<String> = .copy,
        mimeType: CopiableProp<String> = .copy,
        src: CopiableProp<String> = .copy,
        alt: NullableCopiableProp<String> = .copy,
        details: NullableCopiableProp<WordPressMedia.MediaDetails> = .copy,
        title: NullableCopiableProp<WordPressMedia.MediaTitle> = .copy
    ) -> WordPressMedia {
        let mediaID = mediaID ?? self.mediaID
        let date = date ?? self.date
        let slug = slug ?? self.slug
        let mimeType = mimeType ?? self.mimeType
        let src = src ?? self.src
        let alt = alt ?? self.alt
        let details = details ?? self.details
        let title = title ?? self.title

        return WordPressMedia(
            mediaID: mediaID,
            date: date,
            slug: slug,
            mimeType: mimeType,
            src: src,
            alt: alt,
            details: details,
            title: title
        )
    }
}
