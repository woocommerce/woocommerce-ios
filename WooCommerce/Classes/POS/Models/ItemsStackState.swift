import Foundation
import enum Yosemite.POSItem
import Codegen

struct ItemsStackState {
    let root: ItemListState
}

extension ItemsStackState: Equatable, GeneratedCopiable {}
