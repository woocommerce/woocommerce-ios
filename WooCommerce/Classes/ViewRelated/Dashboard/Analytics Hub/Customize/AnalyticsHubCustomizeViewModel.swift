import Foundation

/// View model for `AnalyticsHubCustomizeView`.
final class AnalyticsHubCustomizeViewModel: ObservableObject {

    /// Ordered array of all available analytics cards.
    ///
    @Published var allCards: [String]

    /// Set of selected analytics cards, to be enabled in the Analytics Hub.
    ///
    @Published var selectedCards: Set<String>

    init(allCards: [String],
         selectedCards: Set<String>) {
        self.allCards = allCards
        self.selectedCards = selectedCards
    }
}
