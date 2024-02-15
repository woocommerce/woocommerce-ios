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
        self.allCards = allCards
        self.originalCards = allCards
        self.selectedCards = selectedCards
        self.originalSelection = selectedCards
    }
}
