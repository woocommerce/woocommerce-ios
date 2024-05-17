import SwiftUI

public final class PointOfSaleHistoryViewModel: ObservableObject {
    @Published var items: [HistoryItem]
    @Published var sessionStart: Date? = Date()

    init(items: [HistoryItem]) {
        self.items = items
    }

    static func makeFakeHistory() -> PointOfSaleHistoryViewModel {
        return PointOfSaleHistoryViewModel(items: [
            HistoryItem(createdAt: Date(), amountInCents: 299),
            HistoryItem(createdAt: Date() - 1000, amountInCents: 399)
        ])
    }

    func addItem(_ item: HistoryItem) {
        self.items.append(item)
    }

    var itemsAmount: Int {
        let amount = items.reduce(0) { $0 + $1.amountInCents }
        return amount
    }
}
