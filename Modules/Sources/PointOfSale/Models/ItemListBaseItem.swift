import Foundation
import enum Yosemite.POSItem

enum ItemListBaseItem {
    case root
    case parent(POSItem)
}
