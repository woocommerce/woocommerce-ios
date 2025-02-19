import Foundation
import Observation

@available(iOS 17.0, *)
@Observable class ItemsViewState {
    var containerState: ItemsContainerState
    var itemsStack: ItemsStackState

    init(containerState: ItemsContainerState, itemsStack: ItemsStackState) {
        self.containerState = containerState
        self.itemsStack = itemsStack
    }
}

@available(iOS 17.0, *)
extension ItemsViewState: Equatable {
    static func == (lhs: ItemsViewState, rhs: ItemsViewState) -> Bool {
        return lhs.containerState == rhs.containerState
        && lhs.itemsStack == rhs.itemsStack
    }
}
