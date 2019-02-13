# Core Data Migrations

This file documents changes in the WCiOS Storage data model. Please explain any changes to the data model as well as any custom migrations.

## Model 10 (Release 1.3.0.0)
- @astralbodies 2019-02-08
    - Changes `quantity` attribute on `OrderItem` from Int64 to Decimal

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
