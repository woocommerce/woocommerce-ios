import UIKit
import Yosemite

extension ProductsSortOrder {
    /// Title shown on the action sheet.
    ///
    var actionSheetTitle: String {
        switch self {
        case .dateAscending:
            return NSLocalizedString("Date: Oldest to Newest", comment: "Action sheet option to sort products from the oldest to the newest")
        case .dateDescending:
            return NSLocalizedString("Date: Newest to Oldest", comment: "Action sheet option to sort products from the newest to the oldest")
        case .nameAscending:
            return NSLocalizedString("Title: A to Z", comment: "Action sheet option to sort products by ascending product name")
        case .nameDescending:
            return NSLocalizedString("Title: Z to A", comment: "Action sheet option to sort products by descending product name")
        }
    }
}
