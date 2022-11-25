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
}

/// Convenience extension to create an `AnalyticsReportCard` from a view model.
///
extension AnalyticsProductCard {
    init(viewModel: AnalyticsProductCardViewModel) {
        self.itemsSold = viewModel.itemsSold
        self.delta = viewModel.delta
        self.deltaBackgroundColor = viewModel.deltaBackgroundColor
    }
}
