import Foundation
import Yosemite

extension Optional: FilterType where Wrapped: FilterType {
    var description: String {
        return self?.description ?? NSLocalizedString("Any", comment: "Title when there is no filter set.")
    }

    var isActive: Bool {
        return self != nil
    }
}

extension ProductStockStatus: FilterType {
    var isActive: Bool {
        return true
    }
}

extension ProductStatus: FilterType {
    var isActive: Bool {
        return true
    }
}

extension ProductType: FilterType {
    var isActive: Bool {
        return true
    }
}
