import Foundation
import Yosemite

/// View model for `AnalyticsHubCustomizeView`.
final class AnalyticsHubCustomizeViewModel: ObservableObject {

    /// Ordered array of all available analytics cards.
    ///
    @Published var allCards: [AnalyticsCard]

    /// Set of selected analytics cards, to be enabled in the Analytics Hub.
    ///
    @Published var selectedCards: Set<AnalyticsCard>

    /// Original ordered array of analytics cards. Used to track if there are order changes to be saved.
    ///
    private let originalCards: [AnalyticsCard]

    /// Original set of selected cards. Used to track if there are selection changes to be saved.
    ///
    private let originalSelection: Set<AnalyticsCard>?

    /// Whether there are changes to be saved (card order or selection has changed).
    ///
    var hasChanges: Bool {
        allCards != originalCards || selectedCards != originalSelection
    }

    init(allCards: Set<AnalyticsCard>) {
        let groupedCards = AnalyticsHubCustomizeViewModel.groupSelectedCards(in: allCards)
        self.allCards = groupedCards
        self.originalCards = groupedCards

        let selectedCards = allCards.filter { $0.enabled }
        self.selectedCards = selectedCards
        self.originalSelection = selectedCards
    }
}

private extension AnalyticsHubCustomizeViewModel {
    /// Groups the selected cards at the start of the list of all cards.
    /// This preserves the relative order of selected and unselected cards.
    ///
    static func groupSelectedCards(in allCards: Set<AnalyticsCard>) -> [AnalyticsCard] {
        var groupedCards = Array(allCards).sorted() // Sort cards by sort order
        _ = groupedCards.stablePartition(by: { !$0.enabled }) // Group cards by enabled status
        return groupedCards
    }
}

// MARK: Data for SwiftUI previews
extension AnalyticsHubCustomizeViewModel {
    /// Sample cards to display in the SwiftUI preview
    ///
    static let sampleCards: Set<AnalyticsCard> = [
        AnalyticsCard(type: .revenue, enabled: true, sortOrder: 0),
        AnalyticsCard(type: .orders, enabled: false, sortOrder: 1),
        AnalyticsCard(type: .products, enabled: true, sortOrder: 2),
        AnalyticsCard(type: .sessions, enabled: false, sortOrder: 3)
    ]
}
