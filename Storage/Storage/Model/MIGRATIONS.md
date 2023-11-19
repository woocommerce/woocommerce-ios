# Core Data Migrations

This file documents changes in the WCiOS Storage data model. Please explain any changes to the data model as well as any custom migrations.

## Model 103 (Release 16.3.0.0)
- @ecarrion 2023-11-20
    - Added `storeID` attribute to `Site` entity.

## Model 102 (Release 16.2.0.0)
- @jaclync 2023-11-15
    - Added `bundleMinSize` and `bundleMaxSize` attributes to `Product` entity.

## Model 101 (Release 16.1.0.0)
- @hafizrahman 2023-11-02
    - Added `productID` attribute to `BlazeCampaign` entity.

## Model 100 (Release 15.8.0.0)
- @itsmeichigo 2023-10-11
    - Added new entity `BlazeCampaign`

## Model 99 (Release 15.7.0.0)
- @jaclync 2023-09-27
    - Added `minQuantity`, `maxQuantity`, `defaultQuantity`, `isOptional`, `allowedVariations`, `overridesDefaultVariationAttributes`, `overridesVariations` attributes and `defaultVariationAttributes` relationship to `ProductBundleItem` entity.

## Model 98 (Release 15.4.0.0)
- @hihuongdo 2023-09-15
    - Added `isSampleItem` attribute to `Product` entity.
- @selanthiraiyan 2023-09-14
    - Added `isAIAssitantFeatureActive` attribute to `Site` entity.
    
## Model 97 (Release 15.3.0.0)
- @cvargascasaseca 2023-09-06
    - Added custom class to Transformables in `TaxRate` entity.
    
## Model 96 (Release 15.3.0.0)
- @cvargascasaseca 2023-08-30
    - Added `siteID` attribute to `TaxRate` entity`.
    - Added `NSSecureUnarchiveFromDataTransformer` to Transformable attributes in `TaxRate` entity`.

## Model 95 (Release 15.2.0.0)
- @cvargascasaseca 2023-08-30
    - Added `TaxRate` entity`.

## Model 94 (Release 15.2.0.0)
- @jaclync 2023-08-30
    - Added `OrderItemProductAddOn` entity with many-to-one relationship to `OrderItem`.
    
## Model 93 (Release 14.8.0.0)
- @cvargascasaseca 2023-08-03
    - Added `username` entity attribute to `Customer` entity.

## Model 92 (Release 14.7.0.0)
- @itsmeichigo 2023-07-25
    - Added `wasEcommerceTrial` attribute to `Site` entity.

## Model 91 (Release 14.2.0.0)
- @jaclync 2023-06-20
    - Added `isAdmin` and `canBlaze` attributes to `Site` entity.

## Model 90 (Release 14.1.0.0)
- @iamgabrielma 2023-06-14
    - Added `isSiteOwner` attribute to `Site` entity.

## Model 89 (Release 14.1.0.0)
- @rachelmcr 2023-06-13
    - Removed `couponDiscount` attribute from `OrderStatsV4Totals` entity.
    - Removed `totalCoupons` attribute from `OrderStatsV4Totals` entity.
    - Removed `refunds` attribute from `OrderStatsV4Totals` entity.
    - Removed `taxes` attribute from `OrderStatsV4Totals` entity.
    - Removed `shipping` attribute from `OrderStatsV4Totals` entity.
    - Removed `totalProducts` attribute from `OrderStatsV4Totals` entity.

## Model 88 (Release 13.8.0.0)
- @rachelmcr 2023-05-22
    - Update `amount` attribute on `OrderGiftCard` entity to `Double` type.

## Model 87 (Release 13.7.0.0)
- @rachelmcr 2023-05-17
    - Added `parent` attribute to `OrderItem` entity.

## Model 86 (Release 13.4.0.0)
- @rachelmcr 2023-04-27
    - Added `minAllowedQuantity` attribute to `Product` and `ProductVariation` entities.
    - Added `maxAllowedQuantity` attribute to `Product` and `ProductVariation` entities.
    - Added `groupOfQuantity` attribute to `Product` and `ProductVariation` entities.
    - Added `combineVariationQuantities` attribute to `Product` entity.
    - Added `overrideProductQuantities` attribute to `ProductVariation` entity.

## Model 85 (Release 13.4.0.0)
- @rachelmcr 2023-04-25
    - Added `renewalSubscriptionID` attribute to `Order` entity.
    - Added `OrderGiftCard` entity.
    - Added `appliedGiftCards` to-many relationship from `Order` to `OrderGiftCard`.

## Model 84 (Release 13.3.0.0)
- @selanthiraiyan 2023-04-20
    - Added `isPublic` attribute to `Site` entity.
    
## Model 83 (Release 13.3.0.0)
- @rachelmcr 2023-04-17
    - Added `ProductSubscription` entity.
    - Added relationship between `Product` and `ProductSubscription`.
    - Added relationship between `ProductVariation` and `ProductSubscription`.

## Model 82 (Release 12.9.0.0)
- @rachelmcr 2023-03-20
    - Added `ProductCompositeComponent` entity.
    - Added `compositeComponents` to-many relationship from `Product` to `ProductCompositeComponent`.

## Model 81 (Release 12.8.0.0)
- @rachelmcr 2023-03-13
    - Added `ProductBundleItem` entity.
    - Added `bundledItems` attribute to `Product` entity.
    - Added `bundleStockQuantity` attribute to `Product` entity.
    - Added `bundleStockStatus` attribute to `Product` entity.

## Model 80 (Release 11.7.0.0)
- @rachelmcr 2022-12-15
    - Added `SiteSummaryStats` entity.

## Model 79 (Release 11.7.0.0)
- @rachelmcr 2022-12-12
    - Added `views` attribute to `SiteVisitStatsItem` entity.

## Model 78 (Release 11.4.0.0)
- @rachelmcr 2022-11-18
    - Added `averageOrderValue` attribute to `OrderStatsV4Totals` entity.

## Model 77 (Release 11.2.0.0)
- @ealeksandrov 2022-11-07
    - Added `frameNonce` attribute to `Site` entity.

## Model 76 (Release 11.0.0.0)
- @ealeksandrov 2022-10-26
    - Added `loginURL` attribute to `Site` entity.

## Model 75 (Release 10.9.0.0)
- @iamgabrielma 2022-10-17
    - Added `siteID` attribute to `Customer` entity.
    - Added `siteID` attribute to `CustomerSearchResult` entity.
    - Added `keyword` attribute to `CustomerSearchResult` entity.
    - Removed `customerID` attribute from `CustomerSearchResult` entity.
    - Added `WooCommerceModelV74toV75` mapping model.

## Model 74 (Release 10.8.0.0)
- @iamgabrielma 2022-10-12
    - Added `Customer` entity.
    - Added `CustomerSearchResult` entity.

## Model 73 (Release 10.6.0.0)
- @jaclync 2022-09-14
    - Added `filterKey` attribute to `ProductSearchResults` entity.

## Model 72 (Release 9.6.0.0)
- @joshheald 2022-08-19
    - Added `instructions` attribute to `PaymentGateway` entity.

## Model 71 (Release 9.6.0.0)
- @rachelmcr 2022-07-07
    - Added `OrderMetaData` entity.
    - Added `customFields` to-many relationship from `Order` to `OrderMetaData`.

## Model 70 (Release 9.5.0.0)
- @toupper 2022-06-22
    - Update `OrderItemRefund` entity to include the `refundedItemID` property.

## Model 69 (Release 9.4.0.0)
- @ecarrion 2022-06-08
    - Update `Order` entity to include the `needsProcessing`, `needsPayment`, and `isEditable` properties.

## Model 68 (Release 9.2.0.0)
- @pmusolino 2022-05-05
    - Update `Coupon` entity and make `usageLimit`, `usageLimitPerUser` and `limitUsageToXItems` properties as optional with default value equal to `null`.

## Model 67 (Release 8.9.0.0)
- @ecarrion 2022-04-06
    - Update `Order` entity to include the `paymentURL` property.

## Model 66 (Release 8.8.0.0)
- @pmusolino 2022-03-09
    - Update `Order`'s `items` relationship to be ordered.

## Model 65 (Release 8.6.0.0)
- @joshheald 2022-02-14
    - Added `WCPayCharge` entity.
    - Added `WCPayCardPresentPaymentDetails` entity.
    - Added `WCPayCardPaymentDetails` entity.
    - Added `WCPayCardPresentReceiptDetails` entity.

## Model 64 (Release 8.6.0.0)
- @pmusolino 2022-02-09
    - Added `InboxNote` entity.
    - Added `InboxAction` entity.
    - Added `actions` relationship from `InboxNote` to `[InboxAction]`.

## Model 63 (Release 8.5.0.0)
- @joshheald 2022-01-31
    - Added `chargeID` attribute to `Order` entity.

## Model 62 (Release 8.5.0.0)
- @itsmeichigo 2022-01-25
    - Added `CouponSearchResult` entity.
    - Added `searchResults` relationship from `Coupon` to `CouponSearchResult`.

## Model 61 (Release 8.4.0.0)
- @selanthiraiyan 2022-01-13
    - Added `OrderTaxLine` entity.
    - Added `taxes` relationship from `Order` to `OrderTaxLine`.

## Model 60 (Release 8.3.0.0)
- @ecarrion 2021-12-22
    - Added `OrderKey` attribute to `Order` entity.

## Model 59 (Release 8.2.0.0)
- @jaclync 2021-11-30
    - Added `jetpackConnectionActivePlugins` attribute to `Site` entity.

- @itsmeichigo 2021-12-04
    - Added `adminURL` attribute to `Site` entity.

## Model 58 (Release 8.1.0.0)
- @jaclync 2021-11-15
- Added `isJetpackConnected` attribute to `Site` entity.
- Added `isJetpackThePluginInstalled` attribute to `Site` entity.

## Model 57 (Release 8.0.0.0)
- @allendav 2021-11-03
- Added `isLive` attribute to `PaymentGatewayAccount` entity
- Added `isInTestMode` attribute to `PaymentGatewayAccount` entity

## Model 56 (Release 7.9.0.0)
- @allendav 2021-10-25
- Added `active` attribute to `SystemPlugin` entity

## Model 55 (Release 7.5.0.0)
- @itsmeichigo 2021-08-19
- Added `commercialInvoiceURL` attribute to `ShippingLabel` entity.

## Model 54 (Release 7.2.0.0)
- @fernandofgfer 2021-07-14
- Added `SystemPlugin` entity

## Model 53 (Release 7.0.0.0)
- @pmusolino 2021-06-24
- Added `Country` entity
- Added `StateOfACountry` entity

## Model 52 (Release 6.9.0.0)
- @allendav 2021-06-02
- Added `PaymentGatewayAccount` entity

## Model 51 (Release 6.8.0.0)
- @ealeksandrov 2021-05-21
- Removed `OrderCount` entity
- Removed `OrderCountItem` entity

## Model 50 (Release 6.7.0.0)
- @itsmeichigo 2021-05-05
- Added `SitePlugin` entity.

## Model 49 (Release 6.7.0.0)
- @ecarrion 2021-04-30
- Added `AddOnGroup` entity.
- Added to-many relationship between `AddOnGroup` and `ProductAddOn`.

## Model 48 (Release 6.6.0.0)
- @rachelmcr 2021-04-19
- Added `ShippingLabelAccountSettings` entity.
- Added `ShippingLabelPaymentMethod` entity.

## Model 47 (Release 6.5.0.0)
- @ecarrion 2021-04-09
- Added `ProductAddOnOption` entity.
- Added `ProductAddOn` entity.
- Added to-many relationship between `Product` and  `ProductAddOn`.

## Model 46 (Release 6.2.0.0)
- @rachelmcr 2021-02-18
- Changed `stockQuantity` attribute on `ProductVariation` from Int64 to Decimal.

## Model 45 (Release 6.1.0.0)
- @pmusolino 2021-02-17
- Added `firstName` attribute to `AccountSettings` entity (optional).
- Added `lastName` attribute to `AccountSettings` entity (optional).

## Model 44 (Release 6.0.0.0)
- @jaclync 2021-01-27
- Added `timeRange` attribute to `SiteVisitStats` entity (non-optional and default to empty string).

## Model 43 (Release 6.0.0.0)
- @jaclync 2021-01-22
- Added `siteID` attribute to `SiteVisitStats` and `TopEarnerStats` entity.
- Used mapping model: `WooCommerceModelV42toV43.xcmappingmodel` to remove `SiteVisitStats` and `TopEarnerStats` entities without `siteID`.

## Model 42 (Release 5.9.0.0)
- @ctarda 2021-01-12
- Add `OrderFeeLine`  entity.
- Updated `Order` to add a `fees` relationship

## Model 41 (Release 5.8.0.0)
- @ecarrion 2020-12-30
- Add `ProductAttributeTerm`  entity.
- Updated `ProductAttribute` to add a `terms` relationship

## Model 40 (Release 5.7.0.0)
- @pmusolino 2020-12-07
- Add `siteID` attribute to `ProductAttribute` entity.
- Update `Product`'s `attributes` relationship with `nullify` as delete rule.
- Used mapping model: `WooCommerceModelV39toV40.xcmappingmodel` to remove product attributes without `siteID`.

## Model 39 (Release 5.6.0.0)
- @ecarrion 2020-11-19
- Added  `shippingLines` relationship on `Refund` entity. 

## Model 38 (Release 5.6.0.0)
- @jaclync 2020-11-18
- Added four entities for shipping labels:  `ShippingLabel`, `ShippingLabelAddress`, `ShippingLabelRefund`, and `ShippingLabelSettings`.

## Model 37 (Release 5.5.0.0)
- @ecarrion 2020-12-10
- Added `paymentMethodID` property to `Order` entity.

## Model 36 (Release 5.5.0.0)
- @ecarrion 2020-11-10
- Added `PaymentGateway` entity.
- Fixed warning from `transformable` properties by setting a `NSSecureCoding` value transformer.

## Model 35 (Release 5.5.0.0)
- @jaclync 2020-10-29
- Added `OrderItemAttribute` entity.
- Added  `attributes: [OrderItemAttribute]` relationship to `OrderItem`.

## Model 34 (Release 5.4.0.0)
- @ecarrion 2020-10-21
- Added `ShippingLineTax` entity.
- Added  `taxes` relationship to `ShippingLine`.

## Model 33 (Release 5.4.0.0)
- @jaclync 2020-10-22
- Add `date` attribute to `Product`.
- Used mapping model: `WooCommerceModelV32toV33.xcmappingmodel` to set `Product.date` with `Product.dateCreated`.

## Model 32 (Release 5.2.0.0)
- @shiki 2020-09-28
- Rename `Attribute` to `GenericAttribute`. All existing data are kept.

## Model 31 (Release 5.2.0.0)
- @partho-maple 2020-09-21
- Update `Product`'s `downloads` relationship to be ordered

## Model 30 (Release 5.0.0.0)
- @ecarrion 2020-09-02
- Delete `OrderStats` entity
- Delete `OrderStatsItem` entity

## Model 29 (Release 4.7.0.0)
- @pmusolino 2020-06-29
- Add `siteID` attribute to `ProductTag` entity
- Update `ProductTag`'s  `product` relationship to `products`
- Update `Product`'s `tags` relationship with `nullify` as delete rule
- Used mapping model: `WooCommerceModelV28toV29.xcmappingmodel` to remove product tags without `siteID`

## Model 28 (Release 4.5.0.0)
- @jaclync 2020-06-05
- Add `buttonText` attribute to `Product` entity

## Model 27 (Release 3.9.0.1)
- @ecarrion 2020-03-30
- Update `ProductCategory`'s `product` relationship to `products`
- Add `siteID` and `parentID` to  `ProductCategory` entity 
- Used mapping model: `WooCommerceModelV26toV27.xcmappingmodel` to remove product categories without `siteID`

## Model 26 (Release 3.5.0.0)
- @jaclync 2019-01-14
- Update `Product`'s `images` relationship to be ordered

## Model 25 (Release 3.4.0.0)
- @pmusolino 2019-01-7
- Add `gmtOffset` attribute to `Site` entity

## Model 24 (Release 3.3.0.0)
- @jaclync 2019-12-2
- New `ProductShippingClass` entity
- Add `dateOnSaleStart` attribute to `Product` entity
- Add `dateOnSaleEnd` attribute to `Product` entity
- New `TaxClass` entity

## Model 23 (Release 3.2.0.0)
- @jaclync 2019-11-15
- New `Attribute` entity
- New `ProductVariation` entity
- New `Product.productVariations` relationship

## Model 22 (Release 3.1.0.0)
- @pmusolino 2019-11-4
- New `ShippingLine` entity
- New `Order.shippingLines` relationship

## Model 21 (Release 2.9.0.0)
- @mindgraffiti 2019-10-11
- New `OrderItemTax` entity
- New `OrderItemTaxRefund` entity
- New `OrderItem.taxes` relationship
- New `OrderItemRefund` entity
- New `OrderItemRefund.taxes` relationship
- New `Refund` entity
- New `Refund.items` relationship

## Model 20 (Release 2.8.0.0)
- @jaclync 2019-09-17
- New `ProductSearchResults` entity
- New `Product.searchResults` relationship

- @ctarda 2019-09-24
- Add `reviewerAvatarURL` to `ProductReview` entity

- @mindgraffiti 2019-09-27
- New `OrderRefundCondensed` entity
- New `Order.refunds` relationship

## Model 19 (Release 2.6.0.0)
- @ctarda 2019-08-21
- Add `ProductReview` entity

- @jaclync 2019-08-14
- Add `timezone` attribute to `Site` entity

- @jaclync 2019-08-06
- Add `timeRange` attribute to `OrderStatsV4` entity

## Model 18 (Release 2.5.0.0)
- @ctarda 2019-07-30
    - Add `OrderCount` entity
    - Add `OrderCountItem` entity

## Model 17 (Release 2.3.0.0)
- @ctarda 2019-07-10
    - Add `OrderStatsV4` entity
    - Add `OrderStatsV4Totals` entity
    - Add `OrderStatsV4Interval` entity

## Model 16 (Release 2.0.0.0)
- @mindgraffiti 2019-05-29
    - Add `ProductDownload` entity

## Model 15 (Release 1.9.0.0)
- @mindgraffiti 2019-05-03
    - Delete `ProductVariation` entity
    - Delete `ProductVariationAttribute` entity
    - Delete `ProductVariationDimensions` entity
    - Delete `ProductVariationImage` entity

## Model 14 (Release 1.8.0.0)
- @astralbodies 2019-04-22
    - New `AccountSettings` entity with `tracksOptOut` attribute.
  
## Model 13 (Release 1.6.0.0)
- @bummytime 2019-03-28
    - Added `settingGroupKey` attribute on `SiteSetting` entity
    
- @bummytime 2019-04-01
    - New `ProductVariation` entity
    - New `ProductVariationAttribute` entity
    - New `ProductVariationDimensions` entity
    - New `ProductVariationImage` entity

## Model 12 (Release 1.5.0.0)
- @bummytime 2019-03-20
    - New `Product` entity
    - New `ProductDefaultAttribute` entity
    - New `ProductAttribute` entity
    - New `ProductImage` entity
    - New `ProductTag` entity
    - New `ProductCategory` entity
    - New `ProductDimensions` entity    

- @ctarda 2019-03-14
    - Adds `ShipmentTrackingProvider` and `ShipmentTrackingProviderGroup`

## Model 11 (Release 1.4.0.0)

- @mindgraffiti  2019-02-27
    - Adds  `siteID` and `total` attributes to `OrderStatus` 
    - Changes `name` and `total` on `OrderStatus` to be optional

## Model 10 (Release 1.3.0.0)
Used mapping model: `WooCommerceModelV9toV10.xcmappingmodel`

- @astralbodies 2019-02-08
    - Changes `quantity` attribute on `OrderItem` from Int64 to Decimal

- @bummytime 2019-02-19
    - New `ShipmentTracking` entity
    
- @mindgraffiti 2019-02-21
    - Changes `status` attribute on `Order` to `statusKey`
    - New `OrderStatus` entity

## Model 9 (Release 1.0.0.1) 
- @bummytime 2019-01-11
    - Added `price` attribute on `OrderItem` entity

Note: the 1.0.0 model 9 never made it to our users so we are not reving the version #.

## Model 9 (Release 1.0.0)
- @jleandroperez 2018-12-26
    - New `Order.exclusiveForSearch` property
    - New `OrderSearchResults` entity

## Model 8 (Release 0.13)
- @jleandroperez 2018-12-14
    - Removed  `Site.isJetpackInstalled` attribute.

- @bummytime 2018-12-11
    - New `OrderNote.author` attribute

## Model 7
- @bummytime 2018-11-26
    - New `Note.deleteInProgress` property

## Model 6
- @jleandroperez 2018-11-15
    - New `Note.siteID` property
    
- @jleandroperez 2018-11-12
    - New `Note.subtype` property (optional type)

- @thuycopeland 2018-11-8
    - Added new attribute: `isJetpackInstalled`, to site entity
    - Added new attribute: `plan`, to site entity

## Model 5
- @bummytime 2018-10-26
    - Added new entity: `Note`, to encapsulate all things notifications

- @bummytime 2018-10-23
    - Added new entity: `SiteSetting`, to encapsulate all of the site settings

## Model 4
- @bummytime 2018-10-09
    - Added new entity: `SiteVisitStats`, to encapsulate all of the visitor stats for a given site & granularity
    - Added new entity: `SiteVisitStatsItem`, to encapsulate all the visitor stats for a specific period
    - Added new entity: `OrderStats`, to encapsulate all of the order stats for a given site & granularity
    - Added new entity: `OrderStatsItem`, to encapsulate all the order stats for a specific period

## Model 3
- @bummytime 2018-09-19
    - Widened `quantity` attribute on `OrderItem` from Int16 to Int64
    - Widened `quantity` attribute on `TopEarnerStatsItem` from Int16 to Int64

## Model 2
- @bummytime 2018-09-05
    - Added new entity: `TopEarnerStats`, to encapsulate all of the top earner stats for a given site & granularity
    - Added new entity: `TopEarnerStatsItem`, to encapsulate all the top earner stats for a specific product
