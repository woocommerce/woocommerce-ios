import SwiftUI
import struct Yosemite.TopEarnerStatsItem

/// View model for `DashboardTopPerformersView`.
final class DashboardTopPerformersViewModel: ObservableObject {
    /// UI state of the dashboard top performers.
    enum State {
        /// Shows placeholder rows.
        case loading
        /// Shows either an empty view or a list of top performing rows.
        case loaded(rows: [TopEarnerStatsItem])
    }

    @Published private(set) var isRedacted: Bool = false
    @Published private(set) var rows: [TopPerformersRow.Data] = []

    private var state: State
    private var onTap: (_ item: TopEarnerStatsItem) -> Void

    private let placeholderRows: [TopPerformersRow.Data] = Array(repeating: .init(imageURL: nil,
                                                                                  name: "        ",
                                                                                  details: "",
                                                                                  value: "     "),
                                                                 count: 3)

    init(state: State, onTap: @escaping (_ item: TopEarnerStatsItem) -> Void) {
        self.state = state
        self.onTap = onTap
        update(state: state)
    }

    /// Updates the state based on the data loading status.
    func update(state: State) {
        switch state {
        case .loading:
            isRedacted = true
            rows = placeholderRows
        case .loaded(let items):
            isRedacted = false
            let rows = items.map { item in
                TopPerformersRow.Data(imageURL: URL(string: item.imageUrl ?? ""),
                                      name: item.productName ?? "",
                                      details: Localization.netSales(value: item.totalString),
                                      value: "\(item.quantity)",
                                      tapHandler: { [weak self] in
                    self?.onTap(item)
                })
            }
            self.rows = rows
        }
    }
}

private extension DashboardTopPerformersViewModel {
    enum Localization {
        static func netSales(value: String) -> String {
            String.localizedStringWithFormat(NSLocalizedString("Net sales: %@", comment: "Label for the total sales of a product in the Analytics Hub"),
                                             value)
        }
    }
}
