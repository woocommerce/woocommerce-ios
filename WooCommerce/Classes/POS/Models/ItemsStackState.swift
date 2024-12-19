import Foundation
import Codegen

struct ItemsStackState {
    let root: ItemListState
}

extension ItemsStackState: Equatable, GeneratedCopiable {}
