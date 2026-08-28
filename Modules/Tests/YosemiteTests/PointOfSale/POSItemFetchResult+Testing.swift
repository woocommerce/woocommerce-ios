import Foundation
import struct Networking.PagedItems
@testable import Yosemite

extension POSItemFetchResult {
    var products: PagedItems<POSProduct>? {
        guard case let .products(pagedProducts) = self else {
            return nil
        }
        return pagedProducts
    }

    var items: PagedItems<POSItem>? {
        guard case let .items(pagedItems) = self else {
            return nil
        }
        return pagedItems
    }
}
