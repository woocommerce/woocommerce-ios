import Foundation
import class UIKit.UIColor

/// Analytics Hub Product Card ViewModel.
/// Used to transmit analytics products data.
///
struct AnalyticsProductCardViewModel {
    /// Items Sold Value
    ///
    let itemsSold: String

    /// Items Sold Delta
    ///
    let delta: String

    /// Delta background color.
    ///
    let deltaBackgroundColor: UIColor

    /// Items Solds data to render.
    ///
    let itemsSoldData: [TopPerformersRow.Data]

    /// Indicates if the values should be hidden (for loading state)
    ///
    let isRedacted: Bool

    /// Indicates if there was an error loading the data for the card
    ///
    let showSyncError: Bool
}

extension AnalyticsProductCardViewModel {

    /// Make redacted state of the card, replacing values with hardcoded placeholders
    ///
    var redacted: Self {
        // Values here are placeholders and will be redacted in the UI
        .init(itemsSold: "1000",
              delta: "+50%",
              deltaBackgroundColor: .lightGray,
              itemsSoldData: [.init(imageURL: nil, name: "Product Name", details: "Net Sales", value: "$5678")],
              isRedacted: true,
              showSyncError: false)
    }
}
