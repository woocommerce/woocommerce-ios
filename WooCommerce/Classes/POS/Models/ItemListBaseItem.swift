import Foundation
import enum Yosemite.POSItem

enum ItemListBaseItem {
    case root(ItemType)
    case parent(POSItem, ItemType)
    
    var itemType: ItemType {
        switch self {
        case .root(let type):
            return type
        case .parent(_, let type):
            return type
        }
    }
}
