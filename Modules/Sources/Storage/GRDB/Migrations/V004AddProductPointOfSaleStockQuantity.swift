import Foundation
import GRDB

struct V004AddProductPointOfSaleStockQuantity {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "product") { t in
            t.add(column: "pointOfSaleStockQuantity", .double)
        }

        try db.alter(table: "productVariation") { t in
            t.add(column: "pointOfSaleStockQuantity", .double)
        }
    }
}
