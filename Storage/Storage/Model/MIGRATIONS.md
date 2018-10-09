# Core Data Migrations

This file documents changes in the extensions data model. Please explain any changes to the data model as well as any custom migrations.

## Model 4
- @bummytime 2018-10-09
- Added new entity: `SiteVisitStats`, to encapsulate all of the visitor stats for a given site & granularity
- Added new entity: `SiteVisitStatsItem`, to encapsulate all the visitor stats for a specific period

## Model 3
- @bummytime 2018-09-19
- Widened `quantity` attribute on `OrderItem` from Int16 to Int64
- Widened `quantity` attribute on `TopEarnerStatsItem` from Int16 to Int64

## Model 2
- @bummytime 2018-09-05
- Added new entity: `TopEarnerStats`, to encapsulate all of the top earner stats for a given site & granularity
- Added new entity: `TopEarnerStatsItem`, to encapsulate all the top earner stats for a specific product
