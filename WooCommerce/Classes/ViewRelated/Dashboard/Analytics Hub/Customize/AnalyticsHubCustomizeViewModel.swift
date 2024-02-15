import Foundation

/// View model for `AnalyticsHubCustomizeView`.
final class AnalyticsHubCustomizeViewModel: ObservableObject {

    /// Ordered array of all available analytics cards.
    ///
    @Published var allCards: [String]

    /// Set of selected analytics cards, to be enabled in the Analytics Hub.
    ///
    @Published var selectedCards: Set<String>

    /// Original ordered array of analytics cards. Used to track if there are order changes to be saved.
    ///
    private let originalCards: [String]

    /// Original set of selected cards. Used to track if there are selection changes to be saved.
    ///
    private let originalSelection: Set<String>?

    /// Whether there are changes to be saved (card order or selection has changed).
    ///
    var hasChanges: Bool {
        allCards != originalCards || selectedCards != originalSelection
    }

    init(allCards: [String],
         selectedCards: Set<String>) {
        self.allCards = AnalyticsHubCustomizeViewModel.groupAllCards(allCards, by: selectedCards)
        self.originalCards = AnalyticsHubCustomizeViewModel.groupAllCards(allCards, by: selectedCards)
        self.selectedCards = selectedCards
        self.originalSelection = selectedCards
    }
}

private extension AnalyticsHubCustomizeViewModel {
    /// Groups the selected cards at the start of the list of all cards.
    /// This preserves the relative order of selected and unselected cards.
    ///
    static func groupAllCards(_ allCards: [String], by selectedCards: Set<String>) -> [String] {
        var groupedCards = allCards
        _ = groupedCards.stablePartition(by: { !selectedCards.contains($0) })
        return groupedCards
    }
}
