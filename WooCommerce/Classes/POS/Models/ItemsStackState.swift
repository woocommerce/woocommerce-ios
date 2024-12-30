import Foundation
import Codegen
import enum Yosemite.POSItem

struct ItemsStackState {
    let root: ItemListState
    let itemStates: [POSItem: ItemListState]
}

extension ItemsStackState: Equatable, GeneratedCopiable {}
