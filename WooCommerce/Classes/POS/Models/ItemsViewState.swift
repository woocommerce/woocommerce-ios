import Foundation
import Codegen

struct ItemsViewState {
    var containerState: ItemsContainerState
    var itemsStack: ItemsStackState
}

extension ItemsViewState: GeneratedCopiable, Equatable {}
