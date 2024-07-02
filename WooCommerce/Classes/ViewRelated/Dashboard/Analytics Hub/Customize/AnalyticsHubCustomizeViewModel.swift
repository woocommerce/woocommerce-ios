import Algorithms
import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `AnalyticsHubCustomizeView`.
final class AnalyticsHubCustomizeViewModel: ObservableObject, Identifiable {

    private let analytics: Analytics

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

    /// Inactive analytics cards. These cards are excluded from being selected or reordered.
    ///
    let inactiveCards: [AnalyticsCard]

    /// - Parameters:
    ///   - allCards: An ordered list of all possible analytics cards, with their settings.
    ///   - inactiveCards: Optional list of inactive (unavailable) analytics cards, to exclude them from selecting/reordering.
    ///   - onSave: Optional closure to perform when the changes are saved.
    init(allCards: [AnalyticsCard],
         inactiveCards: [AnalyticsCard] = [],
         analytics: Analytics = ServiceLocator.analytics,
         onSave: (([AnalyticsCard]) -> Void)? = nil) {
        self.inactiveCards = inactiveCards

        let availableCards = AnalyticsHubCustomizeViewModel.availableCards(from: allCards, excluding: inactiveCards)
        let groupedCards = AnalyticsHubCustomizeViewModel.groupSelectedCards(in: availableCards)
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

        analytics.track(event: .AnalyticsHub.customizeAnalyticsSaved(cards: updatedCards))

        // Add back any inactive cards
        updatedCards.append(contentsOf: inactiveCards)

        onSave?(updatedCards)
    }

    func promoURL(for card: AnalyticsCard) -> URL? {
        switch card.type {
        case .bundles:
            WooConstants.URLs.productBundlesExtension.asURL()
        case .sessions:
            WooConstants.URLs.jetpackStats.asURL()
        case .giftCards:
            WooConstants.URLs.giftCardsExtension.asURL()
        case .googleCampaigns:
            WooConstants.URLs.googleAdsExtension.asURL()
        case .revenue, .orders, .products:
            nil
        }
    }
}

private extension AnalyticsHubCustomizeViewModel {
    /// Removes inactive cards from the list of all cards to display in the view.
    ///
    static func availableCards(from allCards: [AnalyticsCard], excluding inactiveCards: [AnalyticsCard]) -> [AnalyticsCard] {
        var allCardsToDisplay = allCards
        allCardsToDisplay.removeAll(where: inactiveCards.contains)
        return allCardsToDisplay
    }

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
