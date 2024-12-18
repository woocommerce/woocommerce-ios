import Foundation
import enum Yosemite.POSItem

enum ItemsNavigationNode {
    case root
    case item(POSItem)
}

extension ItemsNavigationNode: Hashable, Equatable {}
