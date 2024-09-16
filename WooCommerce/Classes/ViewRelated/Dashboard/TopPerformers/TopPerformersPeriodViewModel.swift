import SwiftUI
import struct Yosemite.TopEarnerStatsItem

/// View model for `TopPerformersPeriodView`.
final class TopPerformersPeriodViewModel: ObservableObject {
    /// UI state of the dashboard top performers.
    enum State {
        /// Shows placeholder rows with cached content.
        case loading(cached: [TopEarnerStatsItem])
        /// Shows either an empty view or a list of top performing rows.
        case loaded(rows: [TopEarnerStatsItem])
    }

    /// Defines the possible redacted states
    enum Redacted {
        /// None of the content is redacted
        case none
        /// All content should be redacted
        case full
        /// Some content should be redacted as there is available cached content.
        case cached

        /// Defines if the header should be redacted.
        var header: Bool {
            switch self {
            case .full:
                return true
            case .none, .cached:
                return false
            }
        }

        /// Defines if the item rows should be redacted.
        var rows: Bool {
            switch self {
            case .full:
                return true
            case .none, .cached:
                return false
            }
        }

        /// Defines if the action button should be redacted.
        var actionButton: Bool {
            switch self {
            case .full, .cached:
                return true
            case .none:
                return false
            }
        }
    }

    @Published private(set) var redacted: Redacted = .none
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
        case .loading(let cachedItems):
            let rows = buildRows(items: cachedItems)
            self.redacted = rows.isNotEmpty ? .cached : .full
            self.rows = rows.isNotEmpty ? rows : placeholderRows
        case .loaded(let items):
            redacted = .none
            rows = buildRows(items: items)
        }
    }

    /// Build view rows based on the given `TopEarnerStatsItem`
    private func buildRows(items: [TopEarnerStatsItem]) -> [TopPerformersRow.Data] {
        items.map { item in
            TopPerformersRow.Data(imageURL: URL(string: item.imageUrl ?? ""),
                                  name: item.productName ?? "",
                                  details: Localization.netSales(value: item.totalString),
                                  value: "\(item.quantity)",
                                  tapHandler: { [weak self] in
                self?.onTap(item)
            })
        }
    }
}

private extension TopPerformersPeriodViewModel {
    enum Localization {
        static func netSales(value: String) -> String {
            String.localizedStringWithFormat(NSLocalizedString("Net sales: %@", comment: "Label for the total sales of a product in the Analytics Hub"),
                                             value)
        }
    }
}
