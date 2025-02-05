import Foundation
import Codegen
import enum Yosemite.POSItem
import Observation

@available(iOS 17.0, *)
@Observable final class ItemsStackState {
    var root: ItemListState
    var itemStates: [POSItem: ItemListState]

    init(root: ItemListState, itemStates: [POSItem: ItemListState]) {
        self.root = root
        self.itemStates = itemStates
    }
}

@available(iOS 17.0, *)
extension ItemsStackState: Equatable, GeneratedCopiable {
    static func == (lhs: ItemsStackState, rhs: ItemsStackState) -> Bool {
        return lhs.root == rhs.root
        && lhs.itemStates == rhs.itemStates
    }
}
