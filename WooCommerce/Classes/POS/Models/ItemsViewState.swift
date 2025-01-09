import Foundation
import Codegen

struct ItemsViewState {
    let containerState: ItemsContainerState
    let itemsStack: ItemsStackState
}

extension ItemsViewState: GeneratedCopiable, Equatable {}
