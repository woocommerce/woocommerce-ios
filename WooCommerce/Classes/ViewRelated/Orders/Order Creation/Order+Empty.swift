import Yosemite

extension Order {
    var isEmpty: Bool {
        items.isEmpty && fees.isEmpty
    }
}
