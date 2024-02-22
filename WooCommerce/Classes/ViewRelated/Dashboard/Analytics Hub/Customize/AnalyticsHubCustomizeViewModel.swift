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
    private let originalSelection: Set<AnalyticsCard>

    /// Whether there are changes to be saved (card order or selection has changed).
    ///
    var hasChanges: Bool {
        allCards != originalCards || selectedCards != originalSelection
    }

    /// Callback closure called when the changes are saved.
    ///
    private let onSave: (([AnalyticsCard]) -> Void)?

    init(allCards: [AnalyticsCard],
         onSave: (([AnalyticsCard]) -> Void)? = nil) {
        let groupedCards = AnalyticsHubCustomizeViewModel.groupSelectedCards(in: allCards)
        self.allCards = groupedCards
        self.originalCards = groupedCards

        let selectedCards = Set(allCards.filter { $0.enabled })
        self.selectedCards = selectedCards
        self.originalSelection = selectedCards

        self.onSave = onSave
    }

    /// Assembles the new selections and order into an updated set of cards.
    ///
    func saveChanges() {
        let updatedCards = allCards.map { card in
            card.copy(enabled: selectedCards.contains(card))
        }
        onSave?(updatedCards)
    }
}

private extension AnalyticsHubCustomizeViewModel {
    /// Groups the selected cards at the start of the list of all cards.
    /// This preserves the relative order of selected and unselected cards.
    ///
    static func groupSelectedCards(in allCards: [AnalyticsCard]) -> [AnalyticsCard] {
        var groupedCards = allCards
        _ = groupedCards.stablePartition(by: { !$0.enabled })
        return groupedCards
    }
}

// MARK: Data for SwiftUI previews
extension AnalyticsHubCustomizeViewModel {
    /// Sample cards to display in the SwiftUI preview
    ///
    static let sampleCards = [
        AnalyticsCard(type: .revenue, enabled: true),
        AnalyticsCard(type: .orders, enabled: false),
        AnalyticsCard(type: .products, enabled: true),
        AnalyticsCard(type: .sessions, enabled: false)
    ]
}
