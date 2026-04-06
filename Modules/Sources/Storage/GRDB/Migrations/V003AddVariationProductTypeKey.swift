import Foundation
import GRDB

struct V003AddVariationProductTypeKey {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "productVariation") { t in
            t.add(column: "productTypeKey", .text).notNull().defaults(to: "variation")
        }
    }
}
