import Foundation
import GRDB

struct V003AddVariationTypeKey {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "productVariation") { t in
            t.add(column: "typeKey", .text).notNull().defaults(to: "variation")
        }
    }
}
