import SwiftUI

final class PointOfSaleHistoryViewModel: ObservableObject {
    @Published var items: [HistoryItem]
    @Published var sessionStart: Date?

    init(items: [HistoryItem]) {
        self.items = items
    }

    func addItem(_ item: HistoryItem) {
        self.items.append(item)
    }

    func startSession() {
        sessionStart = Date()
    }

    func endSession() {
        sessionStart = nil
    }

    var itemsAmount: Int {
        let amount = items.reduce(0) { $0 + $1.amountInCents }
        return amount
    }
}
