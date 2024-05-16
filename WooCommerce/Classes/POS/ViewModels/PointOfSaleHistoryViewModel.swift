import SwiftUI

final class PointOfSaleHistoryViewModel: ObservableObject {
    @Published var items: [HistoryItem]

    init(items: [HistoryItem]) {
        self.items = items
    }

    func addItem(_ item: HistoryItem) {
        self.items.append(item)
    }
}
