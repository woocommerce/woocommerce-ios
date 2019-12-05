# Core Data Migrations

This file documents changes in the WCiOS Storage data model. Please explain any changes to the data model as well as any custom migrations.

## Model 24 (Release 3.3.0.0)
- @jaclync 2019-12-2
- New `ProductShippingClass` entity
- Add `dateOnSaleStart` attribute to `Product` entity
- Add `dateOnSaleEnd` attribute to `Product` entity

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
