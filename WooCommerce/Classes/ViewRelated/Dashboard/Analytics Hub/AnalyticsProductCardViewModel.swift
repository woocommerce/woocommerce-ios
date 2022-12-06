import Foundation
import class UIKit.UIColor

/// Analytics Hub Product Card ViewModel.
/// Used to transmit analytics products data.
///
struct AnalyticsProductCardViewModel {
    /// Items Sold Value
    ///
    let itemsSold: String

    /// Items Sold Delta Percentage
    ///
    let delta: DeltaPercentage

    /// Items Solds data to render.
    ///
    let itemsSoldData: [TopPerformersRow.Data]

    /// Indicates if the values should be hidden (for loading state)
    ///
    let isRedacted: Bool

    /// Indicates if there was an error loading stats part of the card.
    ///
    let showStatsError: Bool

    /// Indicates if there was an error loading items sold part of the card.
    ///
    let showItemsSoldError: Bool
}

extension AnalyticsProductCardViewModel {

    /// Make redacted state of the card, replacing values with hardcoded placeholders
    ///
    var redacted: Self {
        // Values here are placeholders and will be redacted in the UI
        .init(itemsSold: "1000",
              delta: DeltaPercentage(string: "0%", direction: .zero),
              itemsSoldData: [.init(imageURL: nil, name: "Product Name", details: "Net Sales", value: "$5678")],
              isRedacted: true,
              showStatsError: false,
              showItemsSoldError: false)
    }

}

/// Convenience extension to create an `AnalyticsReportCard` from a view model.
///
extension AnalyticsProductCard {
    init(viewModel: AnalyticsProductCardViewModel) {
        self.itemsSold = viewModel.itemsSold
        self.delta = viewModel.delta.string
        self.deltaBackgroundColor = viewModel.delta.direction.deltaBackgroundColor
        self.deltaTextColor = viewModel.delta.direction.deltaTextColor
        self.itemsSoldData = viewModel.itemsSoldData
        self.isRedacted = viewModel.isRedacted
        self.showStatsError = viewModel.showStatsError
        self.showItemsSoldError = viewModel.showItemsSoldError

    }
}
