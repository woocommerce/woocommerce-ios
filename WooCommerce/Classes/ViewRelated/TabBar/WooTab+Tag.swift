import Foundation

extension WooTab {
    /// An integer identifier for each tab
    var identifierNumber: Int {
        switch self {
        case .myStore:
            return 0
        case .orders:
            return 1
        case .products:
            return 2
        case .reviews:
            return 3
        }
    }
}
