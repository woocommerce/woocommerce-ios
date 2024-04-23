import Yosemite

final class DashboardCustomizationViewModel: ObservableObject {

    private let analytics: Analytics

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

    /// - Parameters:
    ///   - allCards: An ordered list of all possible dashboard cards, with their settings.
    ///   - inactiveCards: Optional list of inactive (unavailable) dashboard cards, to exclude them from selecting/reordering.
    ///   - onSave: Optional closure to perform when the changes are saved.
    init(allCards: [DashboardCard],
         analytics: Analytics = ServiceLocator.analytics,
         onSave: (([DashboardCard]) -> Void)? = nil) {
        let availableCards = allCards
        let groupedCards = DashboardCustomizationViewModel.groupSelectedCards(in: availableCards)
        self.allCards = groupedCards
        self.originalCards = groupedCards

        let selectedCards = Set(availableCards.filter { $0.enabled })
        self.selectedCards = selectedCards
        self.originalSelection = selectedCards

        self.onSave = onSave
        self.analytics = analytics
    }

    /// Assembles the new selections and order into an updated set of cards.
    ///
    func saveChanges() {
        // Update the selected status of each available card
        var updatedCards = allCards.map { card in
            card.copy(enabled: selectedCards.contains(card))
        }

        // TODO: add tracking

        onSave?(updatedCards)
    }
}

private extension DashboardCustomizationViewModel {
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
        DashboardCard(type: .onboarding, enabled: true),
        DashboardCard(type: .performance, enabled: true),
        DashboardCard(type: .topPerformers, enabled: false),
        DashboardCard(type: .blaze, enabled: true),
    ]
}
