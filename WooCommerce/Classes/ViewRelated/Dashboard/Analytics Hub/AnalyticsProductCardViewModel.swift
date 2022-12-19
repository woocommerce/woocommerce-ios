import Foundation
import class UIKit.UIColor

/// Analytics Hub Products Stats Card ViewModel.
/// Used to transmit analytics products data.
///
struct AnalyticsProductsStatsCardViewModel {
    /// Items Sold Value
    ///
    let itemsSold: String

    /// Items Sold Delta Percentage
    ///
    let delta: DeltaPercentage

    /// Indicates if the values should be hidden (for loading state)
    ///
    let isRedacted: Bool

    /// Indicates if there was an error loading stats part of the card.
    ///
    let showStatsError: Bool
}

/// Analytics Hub Items Sold ViewModel.
/// Used to store top performing products data.
///
struct AnalyticsItemsSoldViewModel {

    /// Items Solds data to render.
    ///
    let itemsSoldData: [TopPerformersRow.Data]

    /// Indicates if the values should be hidden (for loading state)
    ///
    let isRedacted: Bool

    /// Indicates if there was an error loading items sold part of the card.
    ///
    let showItemsSoldError: Bool
}

extension AnalyticsProductsStatsCardViewModel {

    /// Make redacted state of the card, replacing values with hardcoded placeholders
    ///
    var redacted: Self {
        // Values here are placeholders and will be redacted in the UI
        .init(itemsSold: "1000",
              delta: DeltaPercentage(string: "0%", direction: .zero),
              isRedacted: true,
              showStatsError: false)
    }
}

extension AnalyticsItemsSoldViewModel {

    /// Make redacted state of the card, replacing values with hardcoded placeholders
    ///
    var redacted: Self {
        // Values here are placeholders and will be redacted in the UI
        .init(itemsSoldData: [.init(imageURL: nil, name: "Product Name", details: "Net Sales", value: "$5678")],
              isRedacted: true,
              showItemsSoldError: false)
    }
}

/// Convenience extension to create an `AnalyticsProductCard` from a view model.
///
extension AnalyticsProductCard {
    init(statsViewModel: AnalyticsProductsStatsCardViewModel, itemsViewModel: AnalyticsItemsSoldViewModel) {
        // Header with stats
        self.itemsSold = statsViewModel.itemsSold
        self.delta = statsViewModel.delta.string
        self.deltaBackgroundColor = statsViewModel.delta.direction.deltaBackgroundColor
        self.deltaTextColor = statsViewModel.delta.direction.deltaTextColor
        self.isStatsRedacted = statsViewModel.isRedacted
        self.showStatsError = statsViewModel.showStatsError

        // Top performers list
        self.itemsSoldData = itemsViewModel.itemsSoldData
        self.isItemsSoldRedacted = itemsViewModel.isRedacted
        self.showItemsSoldError = itemsViewModel.showItemsSoldError
    }
}
