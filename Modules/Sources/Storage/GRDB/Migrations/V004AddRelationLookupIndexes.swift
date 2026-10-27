import Foundation
import GRDB

/// Adds indexes for the parent lookups used when loading product and variation relations.
struct V004AddRelationLookupIndexes {
    static func migrate(_ db: Database) throws {
        try db.create(index: "productAttribute_on_siteID_productID",
                      on: "productAttribute",
                      columns: ["siteID", "productID"])
        try db.create(index: "productVariation_on_siteID_productID",
                      on: "productVariation",
                      columns: ["siteID", "productID"])
        try db.create(index: "productVariationAttribute_on_siteID_productVariationID",
                      on: "productVariationAttribute",
                      columns: ["siteID", "productVariationID"])
    }
}
