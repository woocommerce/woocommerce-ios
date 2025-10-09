import Foundation
import enum Yosemite.POSItem
import Observation

@Observable final class ItemsStackState {
    var root: ItemListState
    var itemStates: [POSItem: ItemListState]

    init(root: ItemListState, itemStates: [POSItem: ItemListState]) {
        self.root = root
        self.itemStates = itemStates
    }
}

extension ItemsStackState: Equatable {
    static func == (lhs: ItemsStackState, rhs: ItemsStackState) -> Bool {
        return lhs.root == rhs.root
        && lhs.itemStates == rhs.itemStates
    }
}
