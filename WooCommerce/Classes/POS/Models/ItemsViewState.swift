import Foundation
import Codegen

struct ItemsViewState {
    let containerState: ItemsContainerState
    let itemsStack: [ItemsNavigationNode: ItemListState]
}

extension ItemsViewState: GeneratedCopiable, Equatable {}
