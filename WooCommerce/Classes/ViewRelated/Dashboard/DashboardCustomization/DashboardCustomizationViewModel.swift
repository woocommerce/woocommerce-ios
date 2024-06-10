import Yosemite

final class DashboardCustomizationViewModel: ObservableObject {

    /// Ordered array of all available dashboard cards.
    ///
    @Published var allCards: [DashboardCard]

    /// Set of selected dashboard cards, to be enabled on the Dashboard screen.
    ///
    @Published var selectedCards: Set<DashboardCard>

    /// Original ordered array of dashboard cards. Used to track if there are order changes to be saved.
    ///
    private let originalCards: [DashboardCard]

    /// Original set of selected cards. Used to track if there are selection changes to be saved.
    ///
    private let originalSelection: Set<DashboardCard>

    /// Whether there are changes to be saved (card order or selection has changed).
    ///
    var hasChanges: Bool {
        allCards != originalCards || selectedCards != originalSelection
    }

    /// Callback closure called when the changes are saved.
    ///
    private let onSave: (([DashboardCard]) -> Void)?

    /// Inactive dashboard cards. These cards are excluded from being selected or reordered.
    ///
    let inactiveCards: [DashboardCard]

    /// - Parameters:
    ///   - allCards: An ordered list of all possible dashboard cards, with their settings.
    ///   - inactiveCards: Optional list of inactive (unavailable) dashboard cards, to exclude them from selecting/reordering.
    ///   - onSave: Optional closure to perform when the changes are saved.
    init(allCards: [DashboardCard],
         inactiveCards: [DashboardCard] = [],
         onSave: (([DashboardCard]) -> Void)? = nil) {
        self.inactiveCards = inactiveCards

        let availableCards = DashboardCustomizationViewModel.availableCards(from: allCards, excluding: inactiveCards)
        let groupedCards = DashboardCustomizationViewModel.groupSelectedCards(in: availableCards)
        self.allCards = groupedCards
        self.originalCards = groupedCards

        let selectedCards = Set(availableCards.filter { $0.enabled })
        self.selectedCards = selectedCards
        self.originalSelection = selectedCards

        self.onSave = onSave
    }

    /// Assembles the new selections and order into an updated set of cards.
    ///
    func saveChanges() {
        // Update the selected status of each available card
        var updatedCards = allCards.map { card in
            card.copy(enabled: selectedCards.contains(card))
        }

        // Add back any inactive cards
        updatedCards.append(contentsOf: inactiveCards)

        onSave?(updatedCards)
    }
}

private extension DashboardCustomizationViewModel {
    /// Removes inactive cards from the list of all cards to display in the view.
    ///
    static func availableCards(from allCards: [DashboardCard], excluding inactiveCards: [DashboardCard]) -> [DashboardCard] {
        var allCardsToDisplay = allCards
        allCardsToDisplay.removeAll(where: inactiveCards.contains)
        return allCardsToDisplay
    }

    /// Groups the selected cards at the start of the list of all cards.
    /// This preserves the relative order of selected and unselected cards.
    ///
    static func groupSelectedCards(in allCards: [DashboardCard]) -> [DashboardCard] {
        var groupedCards = allCards
        _ = groupedCards.stablePartition(by: { !$0.enabled })
        return groupedCards
    }
}

// MARK: Data for SwiftUI previews
extension DashboardCustomizationViewModel {
    /// Sample cards to display in the SwiftUI preview
    ///
    static let sampleCards = [
        DashboardCard(type: .onboarding, availability: .show, enabled: true),
        DashboardCard(type: .performance, availability: .show, enabled: true),
        DashboardCard(type: .topPerformers, availability: .show, enabled: false),
        DashboardCard(type: .blaze, availability: .show, enabled: true)
    ]
}
