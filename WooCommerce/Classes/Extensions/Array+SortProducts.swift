import Foundation
import enum Yosemite.ProductsSortOrder
import struct Yosemite.Product

extension Array where Element == Product {
    func sortUsing(_ order: ProductsSortOrder) -> [Product] {
        switch order {
        case .dateAscending:
            return sorted(by: { $0.date < $1.date })
        case .dateDescending:
            return sorted(by: { $0.date > $1.date })
        case .nameAscending:
            return sorted(by: { $0.name < $1.name })
        case .nameDescending:
            return sorted(by: { $0.name > $1.name })
        }
    }
}
